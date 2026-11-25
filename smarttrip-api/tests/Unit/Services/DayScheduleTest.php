<?php

namespace Tests\Unit\Services;

use App\Services\Itinerary\DaySchedule;
use PHPUnit\Framework\TestCase;

class DayScheduleTest extends TestCase
{
    private const START = ['lat' => 1.13, 'lng' => 104.03];

    private const MONDAY = 1;

    private static function everyDay(string $open, string $close): array
    {
        return array_fill_keys(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'], [[$open, $close]]);
    }

    private static function stop(float $lngOffset, int $minutes, ?array $hours = null, bool $lunch = false): array
    {
        return ['lat' => 1.13, 'lng' => 104.03 + $lngOffset, 'visit_minutes' => $minutes, 'opening_hours' => $hours, 'lunch' => $lunch];
    }

    private static function plan(array $stops, int $from = 8 * 60, int $until = 17 * 60): array
    {
        return DaySchedule::plan(self::START, self::START, $stops, self::MONDAY, $from, $until);
    }

    public function test_a_place_not_open_yet_comes_after_one_that_is(): void
    {
        $plan = self::plan([
            'opens_at_10' => self::stop(0.005, 60, self::everyDay('10:00', '21:00')),
            'always_open' => self::stop(0.01, 60),
        ]);

        $this->assertTrue($plan['feasible']);
        $this->assertSame(['always_open', 'opens_at_10'], $plan['order']);
        $this->assertGreaterThanOrEqual(10 * 60, $plan['arrivals']['opens_at_10']);
    }

    public function test_a_place_open_only_after_the_day_ends_fails(): void
    {
        $plan = self::plan(['evening_cafe' => self::stop(0.01, 60, self::everyDay('18:00', '24:00'))]);

        $this->assertFalse($plan['feasible']);
        $this->assertSame('evening_cafe', $plan['failed']);
    }

    public function test_a_place_closing_soon_goes_first(): void
    {
        $plan = self::plan([
            'near' => self::stop(0.002, 90),
            'closes_at_10' => self::stop(0.01, 60, self::everyDay('08:00', '10:00')),
        ]);

        $this->assertTrue($plan['feasible']);
        $this->assertSame(['closes_at_10', 'near'], $plan['order']);
    }

    public function test_the_lunch_stop_is_reached_at_lunch_time(): void
    {
        $plan = self::plan([
            'lunch' => self::stop(0.001, 60, null, true),
            'a' => self::stop(0.01, 90),
            'b' => self::stop(0.02, 90),
            'c' => self::stop(0.03, 90),
        ]);

        $this->assertTrue($plan['feasible']);
        $this->assertNotSame('lunch', $plan['order'][0]);
        $this->assertGreaterThanOrEqual(DaySchedule::LUNCH_FROM, $plan['arrivals']['lunch']);
        $this->assertLessThanOrEqual(DaySchedule::LUNCH_UNTIL, $plan['arrivals']['lunch']);
    }

    public function test_visits_are_a_short_gap_apart(): void
    {
        $plan = self::plan(['a' => self::stop(0.01, 60), 'b' => self::stop(0.01, 60)]);

        [$first, $second] = $plan['order'];
        $this->assertSame($plan['arrivals'][$first] + 60 + DaySchedule::GAP_MINUTES, $plan['arrivals'][$second]);
    }

    public function test_a_day_that_runs_past_the_end_time_fails_without_blaming_a_stop(): void
    {
        $plan = self::plan(['a' => self::stop(0.01, 300), 'b' => self::stop(0.02, 300)]);

        $this->assertFalse($plan['feasible']);
        $this->assertNull($plan['failed']);
    }
}
