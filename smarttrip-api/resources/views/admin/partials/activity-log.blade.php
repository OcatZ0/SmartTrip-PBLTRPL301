{{-- F023: Riwayat Perubahan - baca dari activity_log (spatie/laravel-activitylog).
     $activities: Collection<Spatie\Activitylog\Models\Activity> dengan relasi causer di-load.
     $fieldLabels, $formatValue, $describeActivity: dari admin.places.edit. --}}
@php
    $events = [
        'created' => ['label' => 'Ditambahkan', 'icon' => 'bi-plus-lg', 'tone' => 'is-created'],
        'updated' => ['label' => 'Diubah', 'icon' => 'bi-pencil', 'tone' => 'is-updated'],
        'deleted' => ['label' => 'Dihapus', 'icon' => 'bi-trash3', 'tone' => 'is-deleted'],
    ];
    $label = fn ($field) => ucfirst($fieldLabels[$field] ?? str_replace('_', ' ', $field));
    $show = fn ($field, $value) => $value === null || $value === '' ? 'kosong' : $formatValue($field, $value);
@endphp
<div class="pe-card-head">
    <h2>Riwayat Perubahan</h2>
    @if ($activities->isNotEmpty())
        <span class="pe-card-sub">{{ $activities->count() }} catatan</span>
    @endif
</div>

@if ($activities->isEmpty())
    <p class="pe-card-sub mb-0">Belum ada riwayat perubahan.</p>
@else
    <ol class="pe-timeline">
        @foreach ($activities as $activity)
            @php
                $event = $events[$activity->event] ?? $events['updated'];
                $new = collect($activity->attribute_changes?->get('attributes') ?? []);
                $old = collect($activity->attribute_changes?->get('old') ?? []);
            @endphp
            <li class="pe-entry {{ $event['tone'] }}">
                <span class="pe-entry-icon" aria-hidden="true"><i class="bi {{ $event['icon'] }}"></i></span>
                <div class="pe-entry-body">
                    <div class="pe-entry-head">
                        <span><b>{{ $activity->causer?->name ?? 'Sistem' }}</b> {{ $describeActivity($activity) }}</span>
                        <span class="pe-entry-badge">{{ $event['label'] }}</span>
                        <time datetime="{{ $activity->created_at->toIso8601String() }}">{{ $activity->created_at->translatedFormat('j M Y, H.i') }}</time>
                    </div>

                    @if ($activity->event === 'created')
                        @php $filled = $new->reject(fn ($value) => $value === null || $value === ''); @endphp
                        @if ($filled->isNotEmpty())
                            <dl class="pe-entry-fields">
                                @foreach ($filled as $field => $value)
                                    <div>
                                        <dt>{{ $label($field) }}</dt>
                                        <dd>{{ $show($field, $value) }}</dd>
                                    </div>
                                @endforeach
                            </dl>
                        @endif
                    @elseif ($activity->event === 'updated' && $new->isNotEmpty())
                        <ul class="pe-diffs">
                            @foreach ($new as $field => $value)
                                <li>
                                    <span class="pe-diff-field">{{ $label($field) }}</span>
                                    <span class="pe-diff-values">
                                        <span class="pe-diff-old">{{ $show($field, $old->get($field)) }}</span>
                                        <i class="bi bi-arrow-right" aria-label="menjadi"></i>
                                        <span class="pe-diff-new">{{ $show($field, $value) }}</span>
                                    </span>
                                </li>
                            @endforeach
                        </ul>
                    @endif
                </div>
            </li>
        @endforeach
    </ol>
@endif
