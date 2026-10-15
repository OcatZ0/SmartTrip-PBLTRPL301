{{-- Modal konfirmasi hapus, dipakai bersama Kelola Tempat dan Edit Tempat.
     Pemicu: tombol dengan data-confirm-url (DELETE ke URL itu), atau form dengan data-confirm-title
     (submit-nya ditahan dulu). Teks dari data-confirm-title, -text, -ok.
     Form yang dikirim menerima event "confirmed" sesaat sebelum submit. --}}
<div class="modal fade" id="confirmModal" tabindex="-1" aria-labelledby="confirmModalTitle" aria-describedby="confirmModalText" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content confirm-modal">
            <span class="confirm-modal-icon" aria-hidden="true"><i class="bi bi-trash3"></i></span>
            <h2 class="confirm-modal-title" id="confirmModalTitle"></h2>
            <p class="confirm-modal-text" id="confirmModalText"></p>
            <div class="confirm-modal-actions">
                <button type="button" class="confirm-modal-button is-quiet" data-bs-dismiss="modal"><i class="bi bi-x-lg" aria-hidden="true"></i>Batal</button>
                <button type="button" class="confirm-modal-button is-danger" id="confirmModalOk"><i class="bi bi-trash3" aria-hidden="true"></i><span id="confirmModalOkLabel">Hapus</span></button>
            </div>
        </div>
    </div>
</div>
<form id="confirmModalUrlForm" method="POST" class="d-none">
    @csrf
    @method('DELETE')
</form>

@once
@push('styles')
<style>
    .confirm-modal { padding: 32px 28px 24px; border: 0; border-radius: 20px; align-items: center; text-align: center; box-shadow: 0 24px 64px rgba(10, 36, 64, .22); }
    .confirm-modal-icon { width: 64px; height: 64px; margin-bottom: 16px; display: flex; align-items: center; justify-content: center; border-radius: 50%; background: #fdecea; color: #b42318; font-size: 26px; box-shadow: 0 0 0 8px #fef5f4; }
    .confirm-modal-title { margin: 0 0 8px; font-size: 19px; line-height: 26px; font-weight: 700; color: #14212f; overflow-wrap: anywhere; }
    .confirm-modal-text { margin: 0 0 24px; font-size: 14px; color: #5d6b7c; }
    .confirm-modal-actions { width: 100%; display: flex; gap: 12px; }
    .confirm-modal-button { flex: 1; height: 44px; padding: 0 18px; border: 0; border-radius: 12px; display: inline-flex; align-items: center; justify-content: center; gap: 8px; font-size: 14px; font-weight: 700; }
    .confirm-modal-button.is-quiet { background: #eef2f8; color: #14212f; }
    .confirm-modal-button.is-quiet:hover { background: #e2e8f1; }
    .confirm-modal-button.is-danger { background: #d92d20; color: #fff; }
    .confirm-modal-button.is-danger:hover { background: #b42318; }
    .confirm-modal-button:disabled { opacity: .7; }
    .confirm-modal-button:focus-visible { outline: 3px solid rgba(43, 111, 171, .45); outline-offset: 2px; }
</style>
@endpush

@push('scripts')
<script>
    (function () {
        var modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('confirmModal'));
        var okButton = document.getElementById('confirmModalOk');
        var urlForm = document.getElementById('confirmModalUrlForm');
        var pendingForm = null;

        function ask(targetForm, source) {
            pendingForm = targetForm;
            document.getElementById('confirmModalTitle').textContent = source.dataset.confirmTitle || 'Hapus data ini?';
            document.getElementById('confirmModalText').textContent = source.dataset.confirmText || '';
            document.getElementById('confirmModalOkLabel').textContent = source.dataset.confirmOk || 'Hapus';
            okButton.disabled = false;
            modal.show();
        }

        document.addEventListener('click', function (event) {
            var trigger = event.target.closest('[data-confirm-url]');
            if (!trigger) return;
            event.preventDefault();
            urlForm.action = trigger.dataset.confirmUrl;
            ask(urlForm, trigger);
        });

        document.addEventListener('submit', function (event) {
            var form = event.target;
            if (!form.matches('form[data-confirm-title]')) return;
            event.preventDefault();
            ask(form, form);
        });

        okButton.addEventListener('click', function () {
            okButton.disabled = true;
            pendingForm.dispatchEvent(new CustomEvent('confirmed'));
            pendingForm.submit();
        });
    })();
</script>
@endpush
@endonce
