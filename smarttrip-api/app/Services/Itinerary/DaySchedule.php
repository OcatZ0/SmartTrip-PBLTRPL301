<?php

namespace App\Services\Itinerary;

use App\Services\Places\OpeningHours;

/**
 * The order and clock of one day: from the day's start time, go next to the
 * stop that can start soonest (nearest, waiting only when a place is not open
 * yet), unless that would make a stop with a deadline (closing time, lunch)
 * miss it. Arrival must fall inside the opening hours with the whole visit
 * before closing; the lunch stop is reached between 11:00 and 13:30; each
 * stop after the first gets a short gap; the day ends back at its end point
 * by the daily end time. The app replays the same clock for the PDF
 * (itinerary_pdf_plan.dart), so keep the two in step.
 */
class DaySchedule
{
    public const GAP_MINUTES = 10;

    public const LUNCH_FROM = 11 * 60;

    public const LUNCH_UNTIL = 13 * 60 + 30;

    private const DETOUR_FACTOR = 1.35;

    private const AVERAGE_SPEED_KMH = 27.5;

    /**
     * failed is a stop whose hours or lunch time cannot be met; null when the
     * day is only too long.
     *
     * @param  array{lat: float, lng: float}  $start
     * @param  array{lat: float, lng: float}  $end
     * @param  array<int|string, array{lat: float, lng: float, visit_minutes: int, opening_hours?: array|null, lunch?: bool}>  $stops
     * @param  int  $isoWeekday  1 = Monday
     * @return array{order: array<int, int|string>, arrivals: array<int|string, int>, feasible: bool, failed: int|string|null}
     */
    public static function plan(array $start, array $end, array $stops, int $isoWeekday, int $startMinute, int $endMinute): array
    {
        $order = [];
        $arrivals = [];
        $feasible = true;
        $failed = null;
        if ($stops === []) {
            return compact('order', 'arrivals', 'feasible', 'failed');
        }

        $windows = [];
        foreach ($stops as $key => $stop) {
            $windows[$key] = self::windows($stop, $isoWeekday, $endMinute);
        }

        // A day ending somewhere else finishes at the stop closest to that end.
        $remaining = $stops;
        $lastKey = null;
        if (count($stops) >= 2 && Haversine::km($start['lat'], $start['lng'], $end['lat'], $end['lng']) > 0.05) {
            $lastKey = collect($stops)->sortBy(fn ($stop) => Haversine::km($end['lat'], $end['lng'], $stop['lat'], $stop['lng']))->keys()->first();
            unset($remaining[$lastKey]);
        }

        $clock = $startMinute;
        $current = $start;
        $visit = function ($key) use (&$order, &$arrivals, &$clock, &$current, $stops, $windows, &$feasible, &$failed) {
            $begin = self::startAt($clock, $current, $stops[$key], $windows[$key], $order !== []);
            if ($begin === null) {
                $feasible = false;
                $failed ??= $key;
                $begin = (int) round($clock + ($order !== [] ? self::GAP_MINUTES : 0) + self::legMinutes($current, $stops[$key]));
            }
            $order[] = $key;
            $arrivals[$key] = $begin;
            $clock = $begin + $stops[$key]['visit_minutes'];
            $current = $stops[$key];
        };

        while ($remaining !== []) {
            $pick = self::next($remaining, $clock, $current, $stops, $windows, $order !== []);
            $visit($pick);
            unset($remaining[$pick]);
        }
        if ($lastKey !== null) {
            $visit($lastKey);
        }

        if ($clock + self::legMinutes($current, $end) > $endMinute) {
            $feasible = false;
        }

        return compact('order', 'arrivals', 'feasible', 'failed');
    }

    public static function legMinutes(array $from, array $to): float
    {
        return Haversine::estimatedTravelMinutes($from['lat'], $from['lng'], $to['lat'], $to['lng'], self::DETOUR_FACTOR, self::AVERAGE_SPEED_KMH);
    }

    /**
     * The soonest start; a stop whose deadline the soonest one would make it
     * miss goes first instead.
     */
    private static function next(array $remaining, int $clock, array $current, array $stops, array $windows, bool $gap): int|string
    {
        $starts = [];
        foreach ($remaining as $key => $stop) {
            $begin = self::startAt($clock, $current, $stop, $windows[$key], $gap);
            if ($begin !== null) {
                $starts[$key] = $begin;
            }
        }

        // Lunch waits for lunch time while other stops can fill the morning.
        foreach ($starts as $key => $begin) {
            if (($stops[$key]['lunch'] ?? false) && $begin < self::LUNCH_FROM && count($starts) > 1) {
                unset($starts[$key]);
            }
        }

        if ($starts === []) {
            // Nothing fits any more: take the nearest, plan() marks it failed.
            return collect($remaining)->sortBy(fn ($stop) => Haversine::km($current['lat'], $current['lng'], $stop['lat'], $stop['lng']))->keys()->first();
        }

        asort($starts);
        $pick = array_key_first($starts);
        $after = $starts[$pick] + $stops[$pick]['visit_minutes'];

        $urgent = null;
        $urgentDeadline = PHP_INT_MAX;
        foreach (array_keys($starts) as $key) {
            $deadline = self::deadline($stops[$key], $windows[$key]);
            if ($key === $pick || $deadline === null || $deadline >= $urgentDeadline) {
                continue;
            }
            if (self::startAt($after, $stops[$pick], $stops[$key], $windows[$key], true) === null) {
                [$urgent, $urgentDeadline] = [$key, $deadline];
            }
        }

        return $urgent ?? $pick;
    }

    /**
     * When the visit can start if we leave $from at $clock: arrival, or the
     * opening time when early. Null when no window fits the whole visit.
     */
    private static function startAt(int $clock, array $from, array $stop, ?array $windows, bool $gap): ?int
    {
        $arrive = (int) round($clock + ($gap ? self::GAP_MINUTES : 0) + self::legMinutes($from, $stop));
        if ($windows === null) {
            return $arrive;
        }

        foreach ($windows as [$open, $close, $latestStart]) {
            $begin = max($arrive, $open);
            if ($begin + $stop['visit_minutes'] <= $close && $begin <= $latestStart) {
                return $begin;
            }
        }

        return null;
    }

    private static function deadline(array $stop, ?array $windows): ?int
    {
        if ($windows === null) {
            return null;
        }

        return max(array_map(fn ($window) => min($window[1] - $stop['visit_minutes'], $window[2]), $windows));
    }

    /**
     * [open, close, latest start] in minutes after midnight for that weekday,
     * closing no later than the day ends; null when the stop can start any time.
     *
     * @return array<int, array{0: int, 1: int, 2: int}>|null
     */
    private static function windows(array $stop, int $isoWeekday, int $endMinute): ?array
    {
        $day = array_keys(OpeningHours::DAYS)[$isoWeekday - 1];
        $ranges = OpeningHours::periods($stop['opening_hours'] ?? null)[$day] ?? null;
        $lunch = $stop['lunch'] ?? false;

        if ($ranges === null) {
            return $lunch ? [[0, $endMinute, self::LUNCH_UNTIL]] : null;
        }

        $windows = [];
        foreach ($ranges as [$open, $close]) {
            $openMinute = self::minutes($open);
            $closeMinute = self::minutes($close);
            if ($closeMinute <= $openMinute) {
                $closeMinute += 24 * 60;
            }
            $windows[] = [$openMinute, min($closeMinute, $endMinute), $lunch ? self::LUNCH_UNTIL : PHP_INT_MAX];
        }

        return $windows;
    }

    private static function minutes(string $time): int
    {
        [$hour, $minute] = array_map('intval', explode(':', $time));

        return $hour * 60 + $minute;
    }
}
