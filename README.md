# smart_warmth_2025
Applicazione per il controllo del riscaldamento ecologico domestico.

## impostazione icona app e logo app
flutter pub get
dart run flutter_launcher_icons

dart run flutter_native_splash:create

## *************
// Per mostrare un AlertMessage inline
AlertMessage(
    message: "Messaggio di successo",
    subMessage: "Dettagli aggiuntivi qui",
    type: AlertType.success,
)

// Per mostrare uno SnackBar
context.showSuccessSnackBar("Operazione completata");
context.showErrorSnackBar("Si è verificato un errore");

// Per mostrare un Toast
Toast.show(
    context,
    message: "Azione completata",
    type: ToastType.success,
);

// Per mostrare un avviso overlay globale
ref.read(overlayAlertProvider.notifier).show(
    message: "Importante!",
    subMessage: "Questa è una notifica importante",
    type: OverlayAlertType.info,
);