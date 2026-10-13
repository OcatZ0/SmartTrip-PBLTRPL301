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
                                @if ($photo->license)
                                    <div class="text-muted">
                                        {{ $photo->credit ?? 'Tanpa nama' }}, {{ $photo->license }}
                                        @if ($photo->source_url)
                                            <a href="{{ $photo->source_url }}" target="_blank" rel="noopener">sumber</a>
                                        @endif
                                    </div>
                                @else
                                    <div class="text-muted">Unggahan admin</div>
                                @endif
                            </div>
                            <div class="card-footer p-2 d-flex gap-1">
                                @unless ($loop->first)
                                    <form method="POST" action="{{ route('admin.places.photos.primary', [$place, $photo]) }}">
                                        @csrf
                                        <button type="submit" class="btn btn-outline-primary btn-sm">Jadikan utama</button>
                                    </form>
                                @endunless
                                <form method="POST" action="{{ route('admin.places.photos.destroy', [$place, $photo]) }}"
                                    onsubmit="return confirm('Hapus foto ini?')">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="btn btn-outline-danger btn-sm">Hapus</button>
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
                <button type="submit" class="btn btn-primary">Unggah</button>
            </div>
            <div class="form-text">JPG, PNG, atau WebP, maksimal 8 MB per foto, sampai 10 foto sekaligus. Foto dikecilkan otomatis.</div>
        </form>

        <h2 class="h6">Cari foto berlisensi bebas (Openverse)</h2>
        <p class="small text-muted mb-2">
            Foto Creative Commons dari Flickr, Wikimedia, dan lainnya. Hasil pencarian bisa keliru, jadi pilih hanya foto yang
            benar-benar tempat ini. Nama pembuat dan lisensinya ikut tersimpan dan ditampilkan di aplikasi.
        </p>
        <form id="openverse-search" action="{{ route('admin.places.photos.openverse', $place) }}" class="input-group mb-3">
            <input type="text" name="q" class="form-control" maxlength="100" required
                value="{{ str_contains(mb_strtolower($place->name), 'batam') ? $place->name : $place->name.' Batam' }}">
            <button type="submit" class="btn btn-outline-secondary">Cari</button>
        </form>
        <div id="openverse-results" class="row g-3"></div>
    </div>
</div>

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', function () {
    const $form = $('#openverse-search');
    const $results = $('#openverse-results');
    const addUrl = @json(route('admin.places.photos.openverse.store', $place));
    const csrf = @json(csrf_token());

    function message(text, css) {
        $results.empty().append($('<div class="col-12">').append($('<p>').addClass(css).text(text)));
    }

    // Built with .text()/.attr() only: titles and names come from Openverse.
    function candidate(image) {
        const $card = $('<div class="card h-100">');
        $card.append($('<img class="card-img-top object-fit-cover" style="height: 140px" loading="lazy">')
            .attr('src', image.thumbnail || image.url).attr('alt', image.title));

        const $body = $('<div class="card-body p-2 small">');
        $body.append($('<div class="fw-semibold text-truncate">').text(image.title || '(tanpa judul)'));
        $body.append($('<div class="text-muted">').text((image.creator || 'Tanpa nama') + ', ' + image.license));
        if (!image.commercial) {
            $body.append($('<span class="badge text-bg-warning text-white">').text('Hanya non-komersial'));
        }
        if (image.source_url) {
            $body.append($('<div>').append($('<a target="_blank" rel="noopener">').attr('href', image.source_url).text('Lihat sumber')));
        }
        $card.append($body);

        const $add = $('<form method="POST" class="card-footer p-2">').attr('action', addUrl);
        $add.append($('<input type="hidden" name="_token">').val(csrf));
        $add.append($('<input type="hidden" name="openverse_id">').val(image.id));
        $add.append($('<button type="submit" class="btn btn-success btn-sm w-100">').text('Pakai foto ini'));
        $card.append($add);

        return $('<div class="col-6 col-md-3">').append($card);
    }

    $form.on('submit', function (event) {
        event.preventDefault();
        message('Mencari foto...', 'text-muted');

        $.get($form.attr('action'), $form.serialize())
            .done(function (data) {
                if (!data.results.length) {
                    message('Tidak ada foto. Coba nama lain, misalnya nama dalam Bahasa Inggris, atau unggah sendiri.', 'text-muted');
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
