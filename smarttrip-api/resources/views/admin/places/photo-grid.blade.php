{{-- The photo cards of Foto Tempat. Rendered with the edit page and again by
     PlacePhotoController after an upload, a pick or a delete, so the page is
     not reloaded and unsaved edits stay. --}}
<div id="photoGrid">
    @if ($place->photos->isEmpty())
        <p class="text-muted">Belum ada foto. Aplikasi menampilkan gambar kategori sampai foto ditambahkan.</p>
    @else
        <div class="row g-3 mb-4">
            @foreach ($place->photos as $photo)
                <div class="col-6 col-md-3">
                    <div class="card h-100">
                        <img src="{{ $photo->photo_url }}" class="card-img-top object-fit-cover" style="height: 140px" alt="Foto {{ $place->name }}">
                        {{-- One row on every card: main-photo choice on the left, delete on the right.
                             The radio belongs to the edit form (form="formEditPlace"), so a new
                             main photo is only saved with "Simpan perubahan". --}}
                        <div class="card-footer p-2 d-flex align-items-center gap-2">
                            <label class="primary-pick mb-0">
                                <input type="radio" name="primary_photo_id" value="{{ $photo->place_photos_id }}" form="formEditPlace"
                                    @checked((int) old('primary_photo_id', $place->photos->first()->place_photos_id) === $photo->place_photos_id)>
                                <span class="primary-pick-on badge text-bg-primary d-inline-flex align-items-center gap-1 py-2 px-2">
                                    <i class="bi bi-star-fill" aria-hidden="true"></i> Foto utama
                                </span>
                                <span class="primary-pick-off btn btn-link btn-sm text-decoration-none px-1">
                                    <i class="bi bi-star" aria-hidden="true"></i> Jadikan utama
                                </span>
                            </label>
                            <form method="POST" action="{{ route('admin.places.photos.destroy', [$place, $photo]) }}" class="ms-auto" data-photo-ajax
                                data-confirm-title="Hapus foto ini?" data-confirm-ok="Hapus foto" data-confirm-ajax
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
</div>
