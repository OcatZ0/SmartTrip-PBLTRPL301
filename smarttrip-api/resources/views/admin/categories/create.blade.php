@extends('admin.layout')

@section('title', 'Tambah Kategori')

@section('content')
<h1 class="h3 mb-4">Tambah Kategori</h1>

@if ($errors->any())
    <div class="alert alert-danger">
        <ul class="mb-0">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<form method="POST" action="{{ route('admin.categories.store') }}">
    @csrf
    <div class="mb-3">
        <label class="form-label">Nama (Bahasa Indonesia)</label>
        <input type="text" name="name_id" class="form-control" value="{{ old('name_id') }}" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Nama (Inggris)</label>
        <input type="text" name="name_en" class="form-control" value="{{ old('name_en') }}" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Slug</label>
        <input type="text" name="slug" class="form-control" value="{{ old('slug') }}" placeholder="Kosongkan untuk otomatis dari nama Indonesia">
    </div>
    <button type="submit" class="btn btn-primary">Simpan</button>
</form>
@endsection
