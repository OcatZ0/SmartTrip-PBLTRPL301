@extends('admin.layout')

@section('title', 'Edit Kategori')

@section('content')
<h1 class="h3 mb-4">Edit: {{ $category->name_id }}</h1>

@if ($errors->any())
    <div class="alert alert-danger">
        <ul class="mb-0">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<form method="POST" action="{{ route('admin.categories.update', $category) }}">
    @csrf
    @method('PUT')
    <div class="mb-3">
        <label class="form-label">Nama (Bahasa Indonesia)</label>
        <input type="text" name="name_id" class="form-control" value="{{ old('name_id', $category->name_id) }}" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Nama (Inggris)</label>
        <input type="text" name="name_en" class="form-control" value="{{ old('name_en', $category->name_en) }}" required>
    </div>
    <div class="mb-3">
        <label class="form-label">Slug</label>
        <input type="text" name="slug" class="form-control" value="{{ old('slug', $category->slug) }}" required>
    </div>
    <button type="submit" class="btn btn-primary">Simpan</button>
</form>
@endsection
