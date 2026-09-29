@extends('admin.layout')

@section('title', 'Tempat')

@section('content')
<div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="h3 mb-0">Tempat</h1>
    <a href="{{ route('admin.places.create') }}" class="btn btn-primary">Tambah Manual</a>
</div>

@if (session('status'))
    <div class="alert alert-success">{{ session('status') }}</div>
@endif

<form method="GET" action="{{ route('admin.places.index') }}" class="row g-2 mb-3">
    <div class="col-auto">
        <input type="text" name="search" class="form-control" placeholder="Cari nama..." value="{{ $search }}">
    </div>
    <div class="col-auto">
        <input type="text" name="kecamatan" class="form-control" placeholder="Kecamatan..." value="{{ $selectedKecamatan }}">
    </div>
    <div class="col-auto">
        <button type="submit" class="btn btn-outline-secondary">Filter</button>
    </div>
</form>

<table class="table table-bordered table-sm bg-white">
    <thead>
        <tr>
            <th>Nama</th>
            <th>Tipe</th>
            <th>Kecamatan</th>
            <th>Sumber</th>
            <th>Tag Direview?</th>
            <th>Aksi</th>
        </tr>
    </thead>
    <tbody>
        @forelse ($places as $place)
            <tr>
                <td>{{ $place->name }}</td>
                <td>{{ $place->type }}</td>
                <td>{{ $place->kecamatan }}</td>
                <td>{{ $place->source }}</td>
                <td>{{ $place->category_tags_reviewed ? 'Ya' : 'Belum' }}</td>
                <td>
                    <a href="{{ route('admin.places.edit', $place) }}" class="btn btn-sm btn-outline-primary">Edit</a>
                    <form method="POST" action="{{ route('admin.places.destroy', $place) }}" class="d-inline" onsubmit="return confirm('Hapus tempat ini?')">
                        @csrf
                        @method('DELETE')
                        <button type="submit" class="btn btn-sm btn-outline-danger">Hapus</button>
                    </form>
                </td>
            </tr>
        @empty
            <tr><td colspan="6" class="text-center text-muted">Tidak ada tempat.</td></tr>
        @endforelse
    </tbody>
</table>

{{ $places->links() }}
@endsection
