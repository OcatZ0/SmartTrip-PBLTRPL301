<div class="card mt-4" id="photos">
    <div class="card-header">Foto Tempat</div>
    <div class="card-body">
        @if ($place->photos->isEmpty())
            <p class="text-muted">Belum ada foto. Aplikasi menampilkan gambar kategori sampai foto ditambahkan.</p>
        @else
            <div class="row g-3 mb-4">
                @foreach ($place->photos as $photo)
                    <div class="col-6 col-md-3">
                        <div class="card h-100">
                            <img src="{{ $photo->photo_url }}" class="card-img-top object-fit-cover" style="height: 140px" alt="Foto {{ $place->name }}">
                            <div class="card-body p-2 small">
                                @if ($loop->first)
                                    <span class="badge text-bg-primary mb-1">Utama</span>
                                @endif
                            </div>
                            <div class="card-footer p-2 d-flex gap-1">
                                @unless ($loop->first)
                                    <form method="POST" action="{{ route('admin.places.photos.primary', [$place, $photo]) }}">
                                        @csrf
                                        <button type="submit" class="btn btn-outline-primary btn-sm"><i class="bi bi-star" aria-hidden="true"></i> Jadikan utama</button>
                                    </form>
                                @endunless
                                <form method="POST" action="{{ route('admin.places.photos.destroy', [$place, $photo]) }}"
                                    data-confirm-title="Hapus foto ini?" data-confirm-ok="Hapus foto"
                                    data-confirm-text="Foto dihapus dari server dan tidak bisa dikembalikan.">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-outline-danger btn-sm" aria-label="Hapus foto" title="Hapus foto"><i class="bi bi-trash3" aria-hidden="true"></i></button>
                                </form>
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>
        @endif

        <h2 class="h6">Unggah foto</h2>
        <form method="POST" action="{{ route('admin.places.photos.store', $place) }}" enctype="multipart/form-data" class="mb-4">
            @csrf
            <div class="input-group">
                <input type="file" name="photos[]" class="form-control" accept="image/jpeg,image/png,image/webp" multiple required>
                <button type="submit" class="btn btn-primary"><i class="bi bi-upload" aria-hidden="true"></i> Unggah</button>
            </div>
            <div class="form-text">JPG, PNG, atau WebP, maksimal 8 MB per foto, sampai 10 foto sekaligus. Foto dikecilkan otomatis.</div>
        </form>

        @php
            $photoQuery = str_contains(mb_strtolower($place->name), 'batam') ? $place->name : $place->name.' Batam';
            $linkFormOpen = $errors->has('image_url') || old('image_url');
        @endphp
        <h2 class="h6">Cari di Google Gambar</h2>
        <p class="small text-muted mb-2">
            Menampilkan {{ \App\Services\Places\GoogleImagesClient::MAX_RESULTS }} foto teratas. Tiap pencarian baru memakai 1 kuota SerpApi,
            pencarian yang sama dalam sehari tidak. Pilih hanya foto yang benar-benar tempat ini.
        </p>
        <form id="google-search" action="{{ route('admin.places.photos.google', $place) }}" class="input-group mb-3">
            <input type="text" name="q" class="form-control" maxlength="100" required value="{{ $photoQuery }}">
            <button type="submit" class="btn btn-outline-primary"><i class="bi bi-google" aria-hidden="true"></i> Cari</button>
        </form>
        <div id="google-results" class="row g-3 mb-3"></div>

        <button type="button" class="btn btn-outline-secondary mb-3" data-bs-toggle="collapse" data-bs-target="#photo-link-form"
            aria-expanded="{{ $linkFormOpen ? 'true' : 'false' }}" aria-controls="photo-link-form">
            <i class="bi bi-link-45deg" aria-hidden="true"></i> Tambah dari tautan
        </button>
        <form method="POST" action="{{ route('admin.places.photos.link.store', $place) }}" id="photo-link-form"
            class="collapse {{ $linkFormOpen ? 'show' : '' }} border rounded-3 p-3 bg-light">
            @csrf
            <div class="row g-3">
                <div class="col-12">
                    <label for="photoLinkImage" class="form-label small fw-semibold">Alamat gambar</label>
                    <input type="url" name="image_url" id="photoLinkImage" class="form-control @error('image_url') is-invalid @enderror"
                        value="{{ old('image_url') }}" maxlength="2000" required placeholder="https://.../foto.jpg">
                    <div class="form-text">Klik kanan gambarnya di halaman sumber, lalu "Salin alamat gambar".</div>
                    @error('image_url')<div class="invalid-feedback">{{ $message }}</div>@enderror
                </div>
                <div class="col-12">
                    <button type="submit" class="btn btn-primary"><i class="bi bi-check2" aria-hidden="true"></i> Simpan foto</button>
                </div>
            </div>
        </form>
    </div>
</div>

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', function () {
    const $form = $('#google-search');
    const $results = $('#google-results');
    const addUrl = @json(route('admin.places.photos.google.store', $place));
    const csrf = @json(csrf_token());

    function message(text, css) {
        $results.empty().append($('<div class="col-12">').append($('<p>').addClass(css).text(text)));
    }

    // Built with .text()/.attr() only: titles and sources come from Google.
    function candidate(image) {
        const $card = $('<div class="card h-100">');
        $card.append($('<img class="card-img-top object-fit-cover" style="height: 160px" loading="lazy">')
            .attr('src', image.thumbnail || image.url).attr('alt', image.title));

        const $body = $('<div class="card-body p-2 small">');
        $body.append($('<div class="fw-semibold text-truncate">').text(image.title || '(tanpa judul)'));
        if (image.source_url) {
            $body.append($('<a target="_blank" rel="noopener" class="text-truncate d-block">')
                .attr('href', image.source_url).text(image.source || 'Lihat sumber'));
        }
        $card.append($body);

        const $add = $('<form method="POST" class="card-footer p-2">').attr('action', addUrl);
        $add.append($('<input type="hidden" name="_token">').val(csrf));
        $add.append($('<input type="hidden" name="image_url">').val(image.url));
        $add.append($('<button type="submit" class="btn btn-success btn-sm w-100">')
            .append('<i class="bi bi-plus-lg" aria-hidden="true"></i> ', document.createTextNode('Pakai foto ini')));
        $card.append($add);

        return $('<div class="col-12 col-md-4">').append($card);
    }

    $form.on('submit', function (event) {
        event.preventDefault();
        $results.empty().append($('<div class="col-12 text-muted">')
            .append('<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>')
            .append(document.createTextNode('Mencari foto...')));

        $.get($form.attr('action'), $form.serialize())
            .done(function (data) {
                if (!data.results.length) {
                    message('Tidak ada foto. Coba kata kunci lain atau unggah sendiri.', 'text-muted');
                    return;
                }
                $results.empty();
                data.results.forEach(function (image) { $results.append(candidate(image)); });
            })
            .fail(function (xhr) {
                message((xhr.responseJSON && xhr.responseJSON.message) || 'Pencarian gagal, coba lagi.', 'text-danger');
            });
    });
});
</script>
@endpush
