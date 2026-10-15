@extends('admin.layout')

@section('title', 'Kandidat Tempat')

@section('subtitle', 'Tinjau tempat baru hasil Discovery sebelum masuk katalog.')

@section('topbar_actions')
    <form method="POST" action="{{ route('admin.candidates.discover') }}">
        @csrf
        <button type="submit" class="admin-topbar-action">Jalankan Discovery</button>
    </form>
@endsection

@section('content')

@if (session('status'))
    <div class="alert alert-success">{{ session('status') }}</div>
@endif
@if (session('error'))
    <div class="alert alert-danger">{{ session('error') }}</div>
@endif

<form method="GET" action="{{ route('admin.candidates.index') }}" class="row g-2 mb-3">
    <div class="col-auto">
        <select name="search_area" class="form-select" onchange="this.form.submit()">
            <option value="">Semua Kecamatan</option>
            @foreach ($areas as $area)
                <option value="{{ $area }}" @selected($selectedArea === $area)>{{ $area }}</option>
            @endforeach
        </select>
    </div>
    <div class="col-auto">
        <select name="status" class="form-select" onchange="this.form.submit()">
            <option value="pending" @selected($selectedStatus === '' || $selectedStatus === 'pending')>Pending</option>
            <option value="approved" @selected($selectedStatus === 'approved')>Approved</option>
            <option value="rejected" @selected($selectedStatus === 'rejected')>Rejected</option>
        </select>
    </div>
</form>

<form method="POST" id="bulk-form">
    @csrf
    <div class="mb-2">
        <button type="submit" formaction="{{ route('admin.candidates.bulk-approve') }}" class="btn btn-sm btn-success">Approve Terpilih</button>
        <button type="submit" formaction="{{ route('admin.candidates.bulk-reject') }}" class="btn btn-sm btn-outline-danger">Reject Terpilih</button>
    </div>

    <table class="table table-bordered table-sm bg-white">
        <thead>
            <tr>
                <th><input type="checkbox" onclick="document.querySelectorAll('.candidate-check').forEach(c => c.checked = this.checked)"></th>
                <th>Nama</th>
                <th>Tipe</th>
                <th>Kecamatan</th>
                <th>Status</th>
                <th>Aksi</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($candidates as $candidate)
                <tr>
                    <td>@if ($candidate->status !== 'approved')<input type="checkbox" class="candidate-check" name="ids[]" value="{{ $candidate->place_candidates_id }}" form="bulk-form" aria-label="Pilih {{ $candidate->name }}">@endif</td>
                    <td>{{ $candidate->name }}</td>
                    <td>{{ $candidate->type }}</td>
                    <td>{{ $candidate->search_area }}</td>
                    <td>{{ $candidate->status }}</td>
                    <td>
                        @if ($candidate->status !== 'approved')
                            <form method="POST" action="{{ route('admin.candidates.approve', $candidate) }}" class="d-inline">
                                @csrf
                                <button type="submit" class="btn btn-sm btn-success">Approve</button>
                            </form>
                        @endif
                        @if ($candidate->status === 'pending')
                            <form method="POST" action="{{ route('admin.candidates.reject', $candidate) }}" class="d-inline">
                                @csrf
                                <button type="submit" class="btn btn-sm btn-outline-danger">Reject</button>
                            </form>
                        @endif
                        @if ($candidate->status === 'approved')
                            <span class="text-muted small">Sudah di katalog</span>
                        @endif
                    </td>
                </tr>
            @empty
                <tr><td colspan="6" class="text-center text-muted">Tidak ada kandidat.</td></tr>
            @endforelse
        </tbody>
    </table>
</form>

{{ $candidates->links() }}
@endsection
