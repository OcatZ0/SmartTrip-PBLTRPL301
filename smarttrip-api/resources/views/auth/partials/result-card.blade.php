{{-- Result of a link a wisatawan opened from email: $success, $heading, $message, $hint. --}}
<div class="auth-card flex w-full max-w-[420px] flex-col items-center gap-4 rounded-3xl bg-white px-6 pb-8 pt-9 text-center text-[#14212f] shadow-[0_30px_60px_-20px_rgba(0,0,0,0.55)] sm:px-8">
    <span class="flex h-16 w-16 items-center justify-center rounded-full {{ $success ? 'bg-[#e7f4ec]' : 'bg-[#fdecea]' }}">
        @if ($success)
            <svg class="h-8 w-8" viewBox="0 0 24 24" fill="none" stroke="#1e6b3a" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>
        @else
            <svg class="h-8 w-8" viewBox="0 0 24 24" fill="none" stroke="#a8321f" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 7v6M12 17h.01"/><circle cx="12" cy="12" r="9"/></svg>
        @endif
    </span>
    <h1 class="m-0 text-[26px] font-extrabold leading-[32px] tracking-[-0.02em]">{{ $heading }}</h1>
    <p class="m-0 text-[15px] leading-[22px] text-[#14212f]">{{ $message }}</p>
    <p class="m-0 rounded-[14px] bg-[#eef2f8] px-4 py-3 text-[13px] leading-[19px] text-[#5d6b7c]">{{ $hint }}</p>
</div>
