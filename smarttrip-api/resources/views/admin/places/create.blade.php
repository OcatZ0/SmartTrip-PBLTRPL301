@extends('admin.layout')

@section('title', 'Tambah Tempat')
@section('heading', 'Tambah Tempat Manual')
@section('back_url', route('admin.places.index'))
@section('back_label', 'Kelola Tempat')

@section('content')

@if ($errors->any())
    <div class="alert alert-danger">
        <ul class="mb-0">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<form method="POST" action="{{ route('admin.places.store') }}">
    @csrf
    <div class="mb-3">
        <label class="form-label">Nama</label>
        <input type="text" name="name" class="form-control" value="{{ old('name') }}" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Tipe</label>
        <select name="type" class="form-select" required>
            <option value="attraction" @selected(old('type') === 'attraction')>Attraction</option>
            <option value="culinary" @selected(old('type') === 'culinary')>Culinary</option>
            <option value="lodging" @selected(old('type') === 'lodging')>Lodging</option>
        </select>
    </div>
    <div class="row">
        <div class="col mb-3">
            <label class="form-label">Latitude</label>
            <input type="text" name="lat" class="form-control" value="{{ old('lat') }}" required>
        </div>
        <div class="col mb-3">
            <label class="form-label">Longitude</label>
            <input type="text" name="lng" class="form-control" value="{{ old('lng') }}" required>
        </div>
    </div>
    <div class="mb-3">
        <label class="form-label">Alamat</label>
        <input type="text" name="address" class="form-control" value="{{ old('address') }}" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Kecamatan</label>
        <input type="text" name="kecamatan" class="form-control" value="{{ old('kecamatan') }}">
    </div>
    <div class="mb-3">
        <label class="form-label">Deskripsi</label>
        <textarea name="description" class="form-control">{{ old('description') }}</textarea>
    </div>
    <div class="row">
        <div class="col mb-3">
            <label class="form-label">Estimasi Biaya (IDR)</label>
            <input type="number" name="estimated_cost_idr" class="form-control" value="{{ old('estimated_cost_idr') }}">
        </div>
        <div class="col mb-3">
            <label class="form-label">Estimasi Durasi Kunjungan (menit)</label>
            <input type="number" name="estimated_visit_minutes" class="form-control" value="{{ old('estimated_visit_minutes') }}">
        </div>
    </div>
    <div class="mb-3 form-check">
        <input type="checkbox" name="is_outdoor" class="form-check-input" id="is_outdoor" value="1" @checked(old('is_outdoor'))>
        <label class="form-check-label" for="is_outdoor">Sensitif Cuaca (Outdoor)</label>
    </div>
    <button type="submit" class="btn btn-primary">Simpan</button>
</form>
@endsection
