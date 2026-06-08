/// Bilingual strings (French primary, Arabic secondary).
/// RTL support is handled via Directionality widgets.
class S {
  // App
  static const String appName = 'نقل';
  static const String appTagline = 'Déménagement simple, rapide et fiable';

  // Auth
  static const String enterPhone = 'Entrez votre numéro';
  static const String phoneHint = '+212 6XX XXX XXX';
  static const String sendOtp = 'Envoyer le code';
  static const String verifyOtp = 'Vérifier le code';
  static const String otpSentTo = 'Code envoyé au ';
  static const String resendOtp = 'Renvoyer le code';
  static const String iAmClient = 'Je suis un client';
  static const String iAmDriver = 'Je suis chauffeur';

  // Onboarding
  static const String ob1Title = 'Déménagez en toute simplicité';
  static const String ob1Subtitle = 'Publiez votre demande et recevez des offres de chauffeurs certifiés à Casablanca et Rabat.';
  static const String ob2Title = 'Comparez et choisissez';
  static const String ob2Subtitle = 'Voyez les prix, les avis et les photos des camions avant de choisir votre chauffeur.';
  static const String ob3Title = 'Paiement simple et sécurisé';
  static const String ob3Subtitle = 'Payez en cash directement au chauffeur. La commission est gérée automatiquement.';
  static const String skip = 'Passer';
  static const String next = 'Suivant';
  static const String getStarted = 'Commencer';

  // Client
  static const String postAJob = 'Publier une demande';
  static const String pickup = 'Adresse de départ';
  static const String dropoff = 'Adresse d\'arrivée';
  static const String jobDescription = 'Décrivez vos affaires';
  static const String addPhotos = 'Ajouter des photos';
  static const String estimatedDistance = 'Distance estimée';
  static const String driverOffers = 'Offres de chauffeurs';
  static const String waitingForOffers = 'En attente d\'offres...';
  static const String selectDriver = 'Choisir ce chauffeur';
  static const String contactViaWhatsApp = 'Contacter via WhatsApp';
  static const String confirmStart = 'Confirmer le départ';
  static const String confirmComplete = 'Confirmer la livraison';
  static const String rateDriver = 'Évaluer le chauffeur';
  static const String myJobs = 'Mes déménagements';

  // Driver
  static const String availableJobs = 'Offres disponibles';
  static const String myWallet = 'Mon portefeuille';
  static const String walletBalance = 'Solde disponible';
  static const String topUpWallet = 'Recharger';
  static const String commissionHistory = 'Historique commissions';
  static const String topUpHistory = 'Historique recharges';
  static const String submitOffer = 'Soumettre une offre';
  static const String yourPrice = 'Votre prix (MAD)';
  static const String commissionNote = 'Commission plateforme (12%): ';
  static const String walletAfterJob = 'Solde après mission: ';
  static const String lowBalanceTitle = 'Solde insuffisant';
  static const String lowBalanceMsg = 'Votre solde est en dessous de 50 MAD. Rechargez pour continuer à accepter des missions.';
  static const String blockedTitle = 'Compte bloqué';
  static const String blockedMsg = 'Votre solde est à zéro. Rechargez votre portefeuille pour reprendre.';

  // Registration
  static const String driverRegistration = 'Inscription chauffeur';
  static const String truckType = 'Type de camion';
  static const String truckPhoto = 'Photo du camion';
  static const String pricePerKm = 'Prix par km (MAD)';
  static const String city = 'Ville';
  static const String submit = 'S\'inscrire';

  // TopUp
  static const String topUpTitle = 'Recharge portefeuille';
  static const String topUpAmount = 'Montant (MAD)';
  static const String topUpReference = 'Référence CashPlus / Wafacash';
  static const String topUpInstructions = 'Envoyez le montant via CashPlus ou Wafacash puis entrez la référence. L\'admin confirmera sous 24h.';
  static const String topUpSubmit = 'Soumettre la recharge';
  static const String topUpPending = 'En attente de confirmation';

  // Shared
  static const String settings = 'Paramètres';
  static const String support = 'Aide & Support';
  static const String liveChat = 'Chat en direct';
  static const String whatsAppSupport = 'Support WhatsApp';
  static const String faq = 'Questions fréquentes';
  static const String profile = 'Profil';
  static const String logout = 'Déconnexion';
  static const String notifications = 'Notifications';
  static const String home = 'Accueil';
  static const String history = 'Historique';
  static const String wallet = 'Portefeuille';

  // Status
  static const String statusOpen = 'Disponible';
  static const String statusMatched = 'Attribué';
  static const String statusInProgress = 'En cours';
  static const String statusCompleted = 'Terminé';
  static const String statusCancelled = 'Annulé';

  // FAQ
  static const List<Map<String, String>> faqItems = [
    {
      'q': 'Comment fonctionne la commission ?',
      'a': 'La plateforme prélève 12% du prix convenu directement depuis le portefeuille du chauffeur après confirmation de la livraison. Le client paie en cash au chauffeur.',
    },
    {
      'q': 'Comment recharger mon portefeuille ?',
      'a': 'Rendez-vous dans la section Portefeuille, cliquez sur Recharger, choisissez le montant et envoyez via CashPlus ou Wafacash. L\'admin confirme sous 24h.',
    },
    {
      'q': 'Comment signaler un chauffeur ?',
      'a': 'Utilisez le chat en direct ou le support WhatsApp. Notre équipe traitera votre signalement sous 2h.',
    },
    {
      'q': 'Puis-je annuler une demande ?',
      'a': 'Oui, tant qu\'aucun chauffeur n\'a été confirmé. Une fois le chauffeur choisi, contactez le support.',
    },
    {
      'q': 'Quelles villes sont couvertes ?',
      'a': 'Casablanca, Rabat et le trajet intercity Casablanca ↔ Rabat.',
    },
  ];
}
