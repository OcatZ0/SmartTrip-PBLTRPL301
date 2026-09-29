@extends('admin.layout')

@section('title', 'Edit Tempat')

@section('content')
<h1 class="h3 mb-4">Edit: {{ $place->name }}</h1>

@if (session('status'))
    <div class="alert alert-success">{{ session('status') }}</div>
@endif
@if ($errors->any())
    <div class="alert alert-danger">
        <ul class="mb-0">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<form method="POST" action="{{ route('admin.places.update', $place) }}">
    @csrf
    @method('PUT')
    <div class="mb-3">
        <label class="form-label">Kecamatan</label>
        <input type="text" name="kecamatan" class="form-control" value="{{ old('kecamatan', $place->kecamatan) }}">
    </div>
    <div class="mb-3">
        <label class="form-label">Deskripsi (Override, Bahasa Indonesia)</label>
        <textarea name="description_override" class="form-control">{{ old('description_override', $place->description_override) }}</textarea>
        <div class="form-text">Kosongkan supaya tetap pakai deskripsi asli dari Google: {{ $place->description }}</div>
    </div>
    <div class="mb-3">
        <label class="form-label">Deskripsi (Inggris)</label>
        <textarea name="description_en" class="form-control">{{ old('description_en', $place->description_en) }}</textarea>
    </div>
    <div class="row">
        <div class="col mb-3">
            <label class="form-label">Estimasi Biaya (IDR)</label>
            <input type="number" name="estimated_cost_idr" class="form-control" value="{{ old('estimated_cost_idr', $place->estimated_cost_idr) }}">
        </div>
        <div class="col mb-3">
            <label class="form-label">Estimasi Durasi Kunjungan (menit)</label>
            <input type="number" name="estimated_visit_minutes" class="form-control" value="{{ old('estimated_visit_minutes', $place->estimated_visit_minutes) }}">
        </div>
    </div>
    <div class="mb-3 form-check">
        <input type="checkbox" name="is_outdoor" class="form-check-input" id="is_outdoor" value="1" @checked(old('is_outdoor', $place->is_outdoor))>
        <label class="form-check-label" for="is_outdoor">Sensitif Cuaca (Outdoor)</label>
    </div>

    <div class="mb-3">
        <label class="form-label">Kategori</label>
        <div>
            @foreach ($categories as $category)
                <div class="form-check form-check-inline">
                    <input type="checkbox" name="category_ids[]" class="form-check-input" id="cat-{{ $category->categories_id }}"
                        value="{{ $category->categories_id }}"
                        @checked($place->categories->contains('categories_id', $category->categories_id))>
                    <label class="form-check-label" for="cat-{{ $category->categories_id }}">{{ $category->name_id }}</label>
                </div>
            @endforeach
        </div>
        <div class="form-text">Menyimpan form ini menandai tag kategori sudah direview admin.</div>
    </div>

    <button type="submit" class="btn btn-primary">Simpan</button>
</form>
@endsection
