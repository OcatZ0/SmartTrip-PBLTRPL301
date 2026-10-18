<?php

namespace Tests\Unit;

use App\Services\Places\OpeningHours;
use PHPUnit\Framework\TestCase;

class OpeningHoursTest extends TestCase
{
    private const MAPS_WEEK = [
        'Senin: 09.00–19.00', 'Selasa: 09.00–19.00', 'Rabu: 09.00–19.00', 'Kamis: 09.00–19.00',
        'Jumat: 09.00–19.00', 'Sabtu: Tutup', 'Minggu: Tutup',
    ];

    public function test_google_maps_lines_become_the_hours_per_day(): void
    {
        $hours = OpeningHours::fromLines(self::MAPS_WEEK);

        $this->assertSame([['09:00', '19:00']], $hours['mon']);
        $this->assertSame([], $hours['sat']);
        $this->assertArrayNotHasKey('weekday_descriptions', $hours);
        $this->assertSame(self::MAPS_WEEK, OpeningHours::describe($hours));
        $this->assertSame([6, 7], OpeningHours::closedWeekdays($hours));
        $this->assertTrue(OpeningHours::isOpenOn($hours, 1));
        $this->assertFalse(OpeningHours::isOpenOn($hours, 7));
    }

    public function test_lines_in_any_order_with_breaks_24_hours_and_english(): void
    {
        $hours = OpeningHours::fromLines([
            'Sunday: Open 24 hours', 'Monday: 9 AM–6 PM', 'Tuesday: 11.00–14.00, 17.00–22.00', 'Wednesday: Closed',
            'Thursday: 18.00–02.00', 'Friday: 9:30–17:00', 'Saturday: 12 PM–12 AM',
        ]);

        $this->assertSame(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'], array_keys($hours));
        $this->assertSame([['09:00', '18:00']], $hours['mon']);
        $this->assertSame([['11:00', '14:00'], ['17:00', '22:00']], $hours['tue']);
        $this->assertSame([], $hours['wed']);
        $this->assertSame([['18:00', '02:00']], $hours['thu']);
        $this->assertSame([['12:00', '00:00']], $hours['sat']);
        $this->assertSame([['00:00', '24:00']], $hours['sun']);
        $this->assertSame('Senin: 09.00–18.00', OpeningHours::describe($hours)[0]);
        $this->assertSame('Minggu: Buka 24 jam', OpeningHours::describe($hours)[6]);
    }

    public function test_days_that_cannot_be_read_are_unknown(): void
    {
        $partial = OpeningHours::fromLines(['Senin: 08.00–18.00', 'Minggu: 07.00–19.00']);
        $odd = OpeningHours::fromLines([...array_slice(self::MAPS_WEEK, 0, 6), 'Minggu: tergantung cuaca']);

        $this->assertSame(['mon' => [['08:00', '18:00']], 'sun' => [['07:00', '19:00']]], $partial);
        $this->assertNull(OpeningHours::isOpenOn($partial, 3));
        $this->assertArrayNotHasKey('sun', $odd);
        $this->assertNull(OpeningHours::isOpenOn($odd, 7));
        // The known days still count: Saturday is closed.
        $this->assertSame([6], OpeningHours::closedWeekdays($odd));
        $this->assertNull(OpeningHours::fromLines(['Buka saat musim liburan']));
    }

    public function test_simple_osm_strings_are_read(): void
    {
        $this->assertSame([7], OpeningHours::closedWeekdays(OpeningHours::fromOsm('Mo-Fr 09:00-17:00; Sa 09:00-12:00')));
        $this->assertSame([], OpeningHours::closedWeekdays(OpeningHours::fromOsm('Mo-Su 12:00-24:00')));
        $this->assertSame([], OpeningHours::closedWeekdays(OpeningHours::fromOsm('24/7')));
        $this->assertSame([1], OpeningHours::closedWeekdays(OpeningHours::fromOsm('Tu-Su 10:00-22:00; Mo off')));
        // Public holiday rules are skipped, the rest is read.
        $this->assertSame([6, 7], OpeningHours::closedWeekdays(OpeningHours::fromOsm('Mo-Fr 09:00-17:00; PH off')));
        $this->assertNull(OpeningHours::fromOsm('Jan-Mar Mo-Fr 09:00-17:00'));
    }

    public function test_nothing_stored_is_unknown(): void
    {
        $this->assertNull(OpeningHours::isOpenOn(null, 1));
        $this->assertSame([], OpeningHours::closedWeekdays(null));
        $this->assertSame([], OpeningHours::describe(null));
    }

    public function test_the_form_rows_round_trip(): void
    {
        $rows = [
            'mon' => ['state' => 'open', 'open' => '09:00', 'close' => '19:00'],
            'tue' => ['state' => 'open', 'open' => '09:00', 'close' => '19:00'],
            'wed' => ['state' => 'closed'], 'thu' => ['state' => '24h'],
            'fri' => ['state' => 'open', 'open' => '18:00', 'close' => '02:00'],
            'sat' => ['state' => 'closed'], 'sun' => ['state' => 'closed'],
        ];

        $hours = OpeningHours::fromForm($rows);

        $this->assertSame(['Senin: 09.00–19.00', 'Selasa: 09.00–19.00', 'Rabu: Tutup', 'Kamis: Buka 24 jam', 'Jumat: 18.00–02.00', 'Sabtu: Tutup', 'Minggu: Tutup'], OpeningHours::describe($hours));
        $this->assertSame(['state' => 'open', 'open' => '18:00', 'close' => '02:00'], OpeningHours::formRows($hours)['fri']);
        $this->assertSame(['state' => '24h', 'open' => '', 'close' => ''], OpeningHours::formRows($hours)['thu']);
    }

    public function test_a_partly_filled_form_keeps_only_the_filled_days(): void
    {
        $hours = OpeningHours::fromForm(['mon' => ['state' => 'closed'], 'tue' => ['state' => '']]);

        $this->assertSame(['mon' => []], $hours);
        $this->assertFalse(OpeningHours::isOpenOn($hours, 1));
        $this->assertNull(OpeningHours::isOpenOn($hours, 2));
        $this->assertSame(['state' => '', 'open' => '', 'close' => ''], OpeningHours::formRows($hours)['tue']);
        $this->assertNull(OpeningHours::fromForm(['mon' => ['state' => '']]));
    }
}
