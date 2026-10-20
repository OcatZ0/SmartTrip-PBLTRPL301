@extends('admin.auth.layout')

@section('title', 'Masuk')

@section('content')
{{-- With JS the form is sent with fetch so the page can play its exit before
     opening the dashboard; without JS it is a normal POST. --}}
<form method="POST" action="{{ route('admin.login.attempt') }}" id="loginForm" class="auth-card flex w-full max-w-[420px] flex-col gap-4 rounded-3xl bg-white px-6 pb-7 pt-9 text-[#14212f] shadow-[0_30px_60px_-20px_rgba(0,0,0,0.55)] sm:px-8">
    @csrf

    <div class="mb-1.5 flex flex-col gap-1.5">
        <h1 class="m-0 text-[28px] font-extrabold leading-[34px] tracking-[-0.02em]">Selamat datang kembali</h1>
        <p class="m-0 text-sm text-[#5d6b7c]">Kelola destinasi dan rekomendasi wisata Batam.</p>
    </div>

    @if (session('status'))
        <p class="m-0 rounded-[14px] bg-[#e7f4ec] px-3.5 py-2.5 text-[13px] font-medium text-[#1e6b3a]">{{ session('status') }}</p>
    @endif

    <div class="flex flex-col gap-1.5">
        <label for="email" class="text-[13px] font-semibold">Email</label>
        <div data-field="email" class="flex h-[52px] items-center gap-2.5 rounded-[14px] border bg-[#eef2f8] px-3.5 focus-within:border-[#2b6fab] focus-within:bg-white focus-within:ring-4 focus-within:ring-[#2b6fab]/20 data-[invalid]:border-[#c0392b] border-transparent" @error('email') data-invalid @enderror>
            <svg class="h-5 w-5 shrink-0" viewBox="0 0 24 24" fill="none" stroke="#5d6b7c" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/></svg>
            <input id="email" name="email" type="email" value="{{ old('email') }}" required autofocus autocomplete="username" placeholder="nama@smarttrip.id" aria-describedby="emailError" class="min-w-0 flex-1 border-0 bg-transparent p-0 text-sm text-[#14212f] placeholder:text-[#5d6b7c] focus:outline-none focus:ring-0">
        </div>
        <p id="emailError" data-error="email" class="m-0 text-xs font-medium text-[#c0392b]" @unless ($errors->has('email')) hidden @endunless>{{ $errors->first('email') }}</p>
    </div>

    <div class="flex flex-col gap-1.5">
        <div class="flex items-baseline justify-between">
            <label for="password" class="text-[13px] font-semibold">Kata sandi</label>
            {{-- tabindex -1 here and on the eye toggle: Tab goes email, password, Masuk. --}}
            <a href="{{ route('admin.password.request') }}" tabindex="-1" class="text-[13px] font-semibold text-[#1f5f99] no-underline hover:text-[#16476d]">Lupa kata sandi?</a>
        </div>
        <div data-field="password" class="flex h-[52px] items-center gap-2.5 rounded-[14px] border bg-[#eef2f8] pl-3.5 pr-1.5 focus-within:border-[#2b6fab] focus-within:bg-white focus-within:ring-4 focus-within:ring-[#2b6fab]/20 data-[invalid]:border-[#c0392b] border-transparent" @error('password') data-invalid @enderror>
            <svg class="h-5 w-5 shrink-0" viewBox="0 0 24 24" fill="none" stroke="#5d6b7c" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>
            <input id="password" name="password" type="password" required autocomplete="current-password" placeholder="Masukkan kata sandi" aria-describedby="passwordError" class="min-w-0 flex-1 border-0 bg-transparent p-0 text-sm text-[#14212f] placeholder:text-[#5d6b7c] focus:outline-none focus:ring-0">
            <button type="button" tabindex="-1" aria-label="Tampilkan kata sandi" aria-pressed="false"
                    onclick="const i=document.getElementById('password');const s=i.type==='password';i.type=s?'text':'password';this.setAttribute('aria-pressed',s);this.setAttribute('aria-label',s?'Sembunyikan kata sandi':'Tampilkan kata sandi')"
                    class="flex h-11 w-11 items-center justify-center rounded-xl border-0 bg-transparent p-0 hover:bg-black/5">
                <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="#5d6b7c" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/></svg>
            </button>
        </div>
        <p id="passwordError" data-error="password" class="m-0 text-xs font-medium text-[#c0392b]" @unless ($errors->has('password')) hidden @endunless>{{ $errors->first('password') }}</p>
    </div>

    <button type="submit" id="loginSubmit" class="flex h-[52px] items-center justify-center gap-2 rounded-[14px] border-0 bg-[#2b6fab] text-[15px] font-bold text-white transition hover:bg-[#245f93] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[#2b6fab]/30 disabled:cursor-wait disabled:opacity-80">
        Masuk
    </button>
</form>
@endsection

@push('scripts')
<script>
    // 5. Exit transition: on a successful login the card shrinks away, the sun
    // sets and the screen dims before the dashboard opens. Errors show in place.
    (function () {
        var form = document.getElementById('loginForm');
        var submit = document.getElementById('loginSubmit');
        var root = document.querySelector('.auth-root');
        var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        function showErrors(errors) {
            ['email', 'password'].forEach(function (field) {
                var message = errors[field] ? errors[field][0] : '';
                var slot = form.querySelector('[data-error="' + field + '"]');
                var box = form.querySelector('[data-field="' + field + '"]');
                slot.textContent = message;
                slot.hidden = !message;
                box.toggleAttribute('data-invalid', !!message);
            });
            var first = form.querySelector('[data-field][data-invalid] input');
            if (first) first.focus();
        }

        form.addEventListener('submit', function (event) {
            if (!window.fetch) return;
            event.preventDefault();
            submit.disabled = true;
            submit.textContent = 'Memeriksa...';

            fetch(form.action, {
                method: 'POST',
                body: new FormData(form),
                headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
                credentials: 'same-origin',
            })
                .then(function (response) {
                    if (response.ok) {
                        return response.json().then(function (body) {
                            root.classList.add('auth-leaving');
                            setTimeout(function () { window.location.assign(body.redirect); }, reduceMotion ? 0 : 700);
                        });
                    }
                    if (response.status === 422) {
                        return response.json().then(function (body) {
                            showErrors(body.errors || {});
                            submit.disabled = false;
                            submit.textContent = 'Masuk';
                        });
                    }
                    // Expired CSRF token or a server error: let the browser post it normally.
                    form.submit();
                })
                .catch(function () { form.submit(); });
        });
    })();
</script>
@endpush
