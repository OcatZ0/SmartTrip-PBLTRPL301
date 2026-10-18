<?php

namespace App\Services\Places;

/**
 * places.opening_hours holds only the hours per day, Monday first:
 *
 *   {"mon": [["09:00", "19:00"]], "sat": [], "sun": [["00:00", "24:00"]]}
 *
 * An empty list is closed that day, ["00:00", "24:00"] is open all day, and
 * a close before its open runs past midnight. A day left out is unknown and
 * counts as open, so does a place with null. The lines the app shows
 * ("Senin: 09.00–19.00") are made from it by describe(), never stored.
 */
class OpeningHours
{
    /** ISO weekday order (1 = Monday). */
    public const DAYS = ['mon' => 'Senin', 'tue' => 'Selasa', 'wed' => 'Rabu', 'thu' => 'Kamis', 'fri' => 'Jumat', 'sat' => 'Sabtu', 'sun' => 'Minggu'];

    private const DAY_NAMES = [
        'senin' => 'mon', 'selasa' => 'tue', 'rabu' => 'wed', 'kamis' => 'thu', 'jumat' => 'fri', "jum'at" => 'fri', 'sabtu' => 'sat', 'minggu' => 'sun',
        'monday' => 'mon', 'tuesday' => 'tue', 'wednesday' => 'wed', 'thursday' => 'thu', 'friday' => 'fri', 'saturday' => 'sat', 'sunday' => 'sun',
    ];

    private const OSM_DAYS = ['mo' => 'mon', 'tu' => 'tue', 'we' => 'wed', 'th' => 'thu', 'fr' => 'fri', 'sa' => 'sat', 'su' => 'sun'];

    private const ALL_DAY = [['00:00', '24:00']];

    /**
     * True or false when the periods say so for that ISO weekday, null when unknown.
     */
    public static function isOpenOn(?array $hours, int $isoWeekday): ?bool
    {
        $periods = self::periods($hours);
        $day = array_keys(self::DAYS)[$isoWeekday - 1] ?? null;

        return $day === null || ! array_key_exists($day, $periods) ? null : $periods[$day] !== [];
    }

    /**
     * ISO weekdays the place is known to be closed on.
     *
     * @return array<int, int>
     */
    public static function closedWeekdays(?array $hours): array
    {
        $periods = self::periods($hours);

        $closed = [];
        foreach (array_keys(self::DAYS) as $index => $day) {
            if (($periods[$day] ?? null) === []) {
                $closed[] = $index + 1;
            }
        }

        return $closed;
    }

    /**
     * The known days of stored hours, Monday first; anything else is dropped.
     *
     * @return array<string, array<int, array{0: string, 1: string}>>
     */
    public static function periods(?array $hours): array
    {
        $periods = [];
        foreach (array_keys(self::DAYS) as $day) {
            if (is_array($hours[$day] ?? null)) {
                $periods[$day] = $hours[$day];
            }
        }

        return $periods;
    }

    /**
     * Lines like Google Maps gives them ("Senin: 11.00–23.00", "Sabtu: Tutup",
     * "Minggu: Buka 24 jam", "Senin: 11.00–14.00, 17.00–22.00", or the English
     * "Monday: 9 AM–6 PM") into stored hours. A line that cannot be read
     * leaves its day unknown; null when no line can be read.
     */
    public static function fromLines(array $lines): ?array
    {
        $periods = [];
        foreach ($lines as $line) {
            if (! is_string($line) || ! preg_match('/^\s*([^:]+?)\s*:\s*(.+)$/u', $line, $match)) {
                continue;
            }
            $day = self::DAY_NAMES[mb_strtolower(trim($match[1]))] ?? null;
            $period = self::parseTimes($match[2]);
            if ($day !== null && $period !== null) {
                $periods[$day] = $period;
            }
        }

        return $periods === [] ? null : self::periods($periods);
    }

    /**
     * Simple OSM opening_hours as Geoapify gives them: "24/7",
     * "Mo-Su 08:00-21:00", "Mo-Fr 09:00-17:00; Sa 09:00-12:00; Su off".
     * Days not named are closed. Public and school holiday rules are skipped,
     * the itinerary has no holidays; anything fancier (months, weeks) is not
     * read and gives null.
     */
    public static function fromOsm(string $osm): ?array
    {
        $osm = trim($osm);
        if ($osm === '24/7') {
            return array_fill_keys(array_keys(self::DAYS), self::ALL_DAY);
        }

        $periods = array_fill_keys(array_keys(self::DAYS), []);
        $osmDays = array_keys(self::OSM_DAYS);
        foreach (preg_split('/\s*;\s*/', $osm) as $rule) {
            if ($rule === '' || preg_match('/^(PH|SH)\b/', $rule)) {
                continue;
            }
            if (! preg_match('/^((?:Mo|Tu|We|Th|Fr|Sa|Su)(?:-(?:Mo|Tu|We|Th|Fr|Sa|Su))?(?:,(?:Mo|Tu|We|Th|Fr|Sa|Su)(?:-(?:Mo|Tu|We|Th|Fr|Sa|Su))?)*)\s+(.+)$/', $rule, $match)) {
                return null;
            }

            $days = [];
            foreach (explode(',', $match[1]) as $span) {
                $ends = explode('-', strtolower($span));
                $from = array_search($ends[0], $osmDays, true);
                $to = array_search($ends[1] ?? $ends[0], $osmDays, true);
                for ($index = $from; ; $index = ($index + 1) % 7) {
                    $days[] = self::OSM_DAYS[$osmDays[$index]];
                    if ($index === $to) {
                        break;
                    }
                }
            }

            $period = [];
            if (! in_array(strtolower(trim($match[2])), ['off', 'closed'], true)) {
                foreach (explode(',', $match[2]) as $range) {
                    if (! preg_match('/^(\d{2}:\d{2})-(\d{2}:\d{2})$/', trim($range), $times)) {
                        return null;
                    }
                    $period[] = [$times[1], $times[2]];
                }
            }

            foreach ($days as $day) {
                $periods[$day] = $period;
            }
        }

        return $periods;
    }

    /**
     * The edit page's seven rows: state "" (not filled), "open", "closed" or
     * "24h", with open/close times "HH:MM" for "open". Null when no row is
     * filled; a row left unfilled leaves its day unknown.
     *
     * @param  array<string, array{state?: string|null, open?: string|null, close?: string|null}>  $rows
     */
    public static function fromForm(array $rows): ?array
    {
        $periods = [];
        foreach (array_keys(self::DAYS) as $day) {
            $row = $rows[$day] ?? [];
            $period = match ($row['state'] ?? '') {
                'closed' => [],
                '24h' => self::ALL_DAY,
                'open' => filled($row['open'] ?? null) && filled($row['close'] ?? null) ? [[$row['open'], $row['close']]] : null,
                default => null,
            };
            if ($period !== null) {
                $periods[$day] = $period;
            }
        }

        return $periods === [] ? null : $periods;
    }

    /**
     * The edit page's rows for stored hours (first range of a day only).
     *
     * @return array<string, array{state: string, open: string, close: string}>
     */
    public static function formRows(?array $hours): array
    {
        $periods = self::periods($hours);
        $rows = [];
        foreach (array_keys(self::DAYS) as $day) {
            $period = $periods[$day] ?? null;
            $rows[$day] = match (true) {
                $period === null => ['state' => '', 'open' => '', 'close' => ''],
                $period === [] => ['state' => 'closed', 'open' => '', 'close' => ''],
                $period === self::ALL_DAY => ['state' => '24h', 'open' => '', 'close' => ''],
                default => ['state' => 'open', 'open' => $period[0][0], 'close' => $period[0][1]],
            };
        }

        return $rows;
    }

    /**
     * @return array<int, string> one line per known day, Monday first
     */
    public static function describe(?array $hours): array
    {
        $lines = [];
        foreach (self::periods($hours) as $day => $period) {
            $lines[] = self::DAYS[$day].': '.match (true) {
                $period === [] => 'Tutup',
                $period === self::ALL_DAY => 'Buka 24 jam',
                default => implode(', ', array_map(
                    fn (array $range) => str_replace(':', '.', $range[0]).'–'.str_replace(':', '.', $range[1]),
                    $period
                )),
            };
        }

        return $lines;
    }

    /**
     * "Tutup", "Buka 24 jam", "11.00–23.00", "9 AM–6 PM", "11.00–14.00, 17.00–22.00".
     */
    private static function parseTimes(string $text): ?array
    {
        $text = mb_strtolower(trim($text));
        if (in_array($text, ['tutup', 'closed', 'libur'], true)) {
            return [];
        }
        if (str_contains($text, '24 jam') || str_contains($text, '24 hours')) {
            return self::ALL_DAY;
        }

        $ranges = [];
        foreach (preg_split('/\s*[,;]\s*/u', $text) as $part) {
            $times = preg_split('/\s*[–—-]\s*/u', $part);
            if (count($times) !== 2) {
                return null;
            }
            [$open, $close] = [self::parseTime($times[0], $times[1]), self::parseTime($times[1])];
            if ($open === null || $close === null || $open === $close) {
                return null;
            }
            $ranges[] = [$open, $close];
        }

        return $ranges === [] ? null : $ranges;
    }

    /**
     * "11.00", "9:30", "9 am", "6 PM" into "HH:MM". A start without am/pm
     * borrows it from the end ("9–6 PM" reads 9 PM, so Google writes "9 AM–6 PM").
     */
    private static function parseTime(string $text, ?string $borrowFrom = null): ?string
    {
        if (! preg_match('/^(\d{1,2})(?:[.:](\d{2}))?\s*(am|pm)?$/u', trim($text), $match)) {
            return null;
        }

        $hour = (int) $match[1];
        $minute = (int) ($match[2] ?? 0);
        $meridiem = $match[3] ?? null;
        if ($meridiem === null && $borrowFrom !== null && preg_match('/(am|pm)\s*$/u', trim($borrowFrom), $borrowed)) {
            $meridiem = $borrowed[1];
        }
        if ($meridiem === 'pm' && $hour < 12) {
            $hour += 12;
        } elseif ($meridiem === 'am' && $hour === 12) {
            $hour = 0;
        }

        if ($hour > 24 || $minute > 59 || ($hour === 24 && $minute > 0)) {
            return null;
        }

        return sprintf('%02d:%02d', $hour, $minute);
    }
}
