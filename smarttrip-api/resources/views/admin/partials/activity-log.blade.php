{{-- F023: Riwayat Perubahan - baca dari activity_log (spatie/laravel-activitylog).
     $activities: Collection<Spatie\Activitylog\Models\Activity> dengan relasi causer di-load. --}}
<div class="mt-4">
    <h2 class="h5">Riwayat Perubahan</h2>

    @if ($activities->isEmpty())
        <p class="text-muted">Belum ada riwayat perubahan.</p>
    @else
        <table class="table table-sm table-bordered bg-white">
            <thead>
                <tr>
                    <th>Waktu</th>
                    <th>Oleh</th>
                    <th>Aksi</th>
                    <th>Perubahan</th>
                </tr>
            </thead>
            <tbody>
                @foreach ($activities as $activity)
                    <tr>
                        <td>{{ $activity->created_at->format('Y-m-d H:i') }}</td>
                        <td>{{ $activity->causer?->name ?? 'Sistem' }}</td>
                        <td>{{ $activity->event }}</td>
                        <td>
                            @php
                                $new = $activity->attribute_changes->get('attributes', collect());
                                $old = $activity->attribute_changes->get('old', collect());
                            @endphp
                            @if ($activity->event === 'created')
                                <ul class="mb-0">
                                    @foreach ($new as $field => $value)
                                        <li><strong>{{ $field }}</strong>: {{ $value }}</li>
                                    @endforeach
                                </ul>
                            @elseif ($activity->event === 'deleted')
                                <span class="text-muted">Dihapus.</span>
                            @else
                                <ul class="mb-0">
                                    @foreach ($new as $field => $value)
                                        <li>
                                            <strong>{{ $field }}</strong>:
                                            "{{ $old[$field] ?? '' }}" &rarr; "{{ $value }}"
                                        </li>
                                    @endforeach
                                </ul>
                            @endif
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif
</div>
