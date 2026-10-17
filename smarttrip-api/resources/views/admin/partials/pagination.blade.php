{{-- Tombol halaman saja: teks "Menampilkan x-y dari z" sudah ditulis halaman pemakainya. --}}
@if ($paginator->hasPages())
    <nav aria-label="Navigasi halaman">
        <ul class="pagination admin-pagination mb-0">
            @if ($paginator->onFirstPage())
                <li class="page-item disabled" aria-disabled="true">
                    <span class="page-link" aria-label="Halaman sebelumnya"><i class="bi bi-chevron-left" aria-hidden="true"></i></span>
                </li>
            @else
                <li class="page-item">
                    <a class="page-link" href="{{ $paginator->previousPageUrl() }}" rel="prev" aria-label="Halaman sebelumnya"><i class="bi bi-chevron-left" aria-hidden="true"></i></a>
                </li>
            @endif

            @foreach ($elements as $element)
                @if (is_string($element))
                    <li class="page-item disabled" aria-disabled="true"><span class="page-link">{{ $element }}</span></li>
                @endif

                @if (is_array($element))
                    @foreach ($element as $page => $url)
                        @if ($page == $paginator->currentPage())
                            <li class="page-item active" aria-current="page"><span class="page-link">{{ $page }}</span></li>
                        @else
                            <li class="page-item"><a class="page-link" href="{{ $url }}" aria-label="Halaman {{ $page }}">{{ $page }}</a></li>
                        @endif
                    @endforeach
                @endif
            @endforeach

            @if ($paginator->hasMorePages())
                <li class="page-item">
                    <a class="page-link" href="{{ $paginator->nextPageUrl() }}" rel="next" aria-label="Halaman berikutnya"><i class="bi bi-chevron-right" aria-hidden="true"></i></a>
                </li>
            @else
                <li class="page-item disabled" aria-disabled="true">
                    <span class="page-link" aria-label="Halaman berikutnya"><i class="bi bi-chevron-right" aria-hidden="true"></i></span>
                </li>
            @endif
        </ul>
    </nav>
@endif

@once
@push('styles')
<style>
    /* Shared by Kelola Tempat and Kandidat Tempat: dark numbers on white, blue only for the current page. */
    .admin-pagination { margin: 0; padding: 0; display: flex; align-items: center; gap: 4px; list-style: none; }
    .admin-pagination .page-link { min-width: 34px; height: 34px; padding: 0 10px; display: flex; align-items: center; justify-content: center; border: 1px solid #E2E8F0; border-radius: 8px !important; background: #FFFFFF; color: #334155; font-size: 13px; font-weight: 700; text-decoration: none; box-shadow: none; transition: background-color .15s ease, border-color .15s ease; }
    .admin-pagination a.page-link:hover { background: #F1F5F9; border-color: #CBD5E1; color: #0F172A; }
    .admin-pagination a.page-link:focus-visible { outline: 3px solid rgba(22, 114, 184, .35); outline-offset: 1px; }
    .admin-pagination .page-item.active .page-link { background: #1672B8; border-color: #1672B8; color: #FFFFFF; }
    .admin-pagination .page-item.disabled .page-link { background: #F8FAFC; border-color: #EEF2F6; color: #CBD5E1; }
</style>
@endpush
@endonce
