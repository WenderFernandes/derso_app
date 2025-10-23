# Sistema de Assinaturas DERSO - Flutter

## 📋 Arquivos Criados

### Modelos
- `subscription_plan.dart` - Define os planos de assinatura (Trial, Mensal, Anual)
- `user_subscription.dart` - Modelo de assinatura do usuário

### Serviços
- `billing_service.dart` - Gerencia compras via Google Play Billing
- `subscription_provider.dart` - Provider para gerenciar estado das assinaturas

### Páginas
- `subscription_page.dart` - Tela de assinaturas com cards dos planos
- `paywall_widget.dart` - Widget para bloquear recursos premium

### Atualizações
- `main.dart` - Atualizado com SubscriptionProvider
- `home_page_updated.dart` - HomePage com verificação de assinatura
- `profile_page_updated.dart` - ProfilePage com status da assinatura

## 📦 Dependências Necessárias

Adicione ao `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Dependências existentes
  provider: ^6.1.1
  google_fonts: ^6.1.0
  intl: ^0.19.0
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  shared_preferences: ^2.2.2
  flutter_local_notifications: ^16.3.0
  timezone: ^0.9.2
  permission_handler: ^11.1.0
  crypto: ^3.0.3
  table_calendar: ^3.0.9
  fl_chart: ^0.66.0
  local_auth: ^2.1.8
  
  # Nova dependência para billing
  in_app_purchase: ^3.1.11
```

Execute:
```bash
flutter pub get
```

## 🏗️ Estrutura de Diretórios

Organize os arquivos:

```
lib/
├── main.dart
├── models/
│   ├── user.dart
│   ├── service.dart
│   ├── subscription_plan.dart
│   └── user_subscription.dart
├── services/
│   ├── database_service.dart
│   ├── notification_service.dart
│   ├── biometric_service.dart
│   └── billing_service.dart
├── providers/
│   ├── user_provider.dart
│   ├── service_provider.dart
│   ├── theme_provider.dart
│   └── subscription_provider.dart
├── pages/
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── home_page.dart
│   ├── calendar_page.dart
│   ├── dashboard_page.dart
│   ├── profile_page.dart
│   ├── edit_profile_page.dart
│   ├── change_password_page.dart
│   ├── service_form_page.dart
│   └── subscription_page.dart
└── widgets/
    ├── gradient_header.dart
    └── paywall_widget.dart
```

## ⚙️ Configuração do Google Play Console

### 1. Criar Produtos de Assinatura

1. Acesse [Google Play Console](https://play.google.com/console)
2. Selecione seu app
3. Vá em **Monetização > Produtos > Assinaturas**
4. Clique em **Criar assinatura**

#### Plano Mensal
- **ID do produto**: `derso_premium_mensal`
- **Nome**: DERSO Premium Mensal
- **Descrição**: Acesso completo ao DERSO com renovação mensal
- **Período de cobrança**: 1 mês
- **Preço**: R$ 5,00
- **Teste gratuito**: 7 dias (configurar em "Ofertas")

#### Plano Anual
- **ID do produto**: `derso_premium_anual`
- **Nome**: DERSO Premium Anual
- **Descrição**: Acesso completo ao DERSO com renovação anual e 2 meses grátis
- **Período de cobrança**: 1 ano
- **Preço**: R$ 50,00
- **Teste gratuito**: 7 dias (configurar em "Ofertas")

### 2. Configurar Ofertas (Trial)

Para cada assinatura:
1. Clique em **Base plans and offers**
2. Clique em **Add offer**
3. Configure:
   - **Tipo**: Teste gratuito
   - **Duração**: 7 dias
   - **Elegibilidade**: Novos assinantes
   - **Fase 1 (Trial)**: Gratuito por 7 dias
   - **Fase 2 (Recorrente)**: Preço normal

### 3. Configurar Testers Licenciados

Para testar compras sem cobranças reais:

1. Vá em **Configuração > Acesso a licenças de teste**
2. Adicione os e-mails Gmail dos testadores
3. Os testadores podem fazer compras de teste sem custo

### 4. Ativar Notificações em Tempo Real

1. Acesse **Monetização > Configuração de monetização**
2. Role até **Notificações em tempo real do desenvolvedor**
3. Clique em **Configurar**
4. Isso será necessário para o backend (configuraremos depois)

## 📱 Configuração do AndroidManifest.xml

Adicione as permissões necessárias em `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissões existentes -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    
    <!-- Permissão para billing -->
    <uses-permission android:name="com.android.vending.BILLING" />
    
    <application
        android:label="DERSO"
        android:icon="@mipmap/ic_launcher">
        <!-- Resto da configuração -->
    </application>
</manifest>
```

## 🧪 Como Testar

### 1. Teste Local (Trial)

O trial de 7 dias funciona localmente sem Google Play:

```dart
// Ao fazer login ou criar conta
final subscriptionProvider = context.read<SubscriptionProvider>();
await subscriptionProvider.startTrial(userId);
```

### 2. Teste com Google Play Billing

1. **Build da versão de teste**:
```bash
flutter build apk --release
```

2. **Upload para Play Console**:
   - Vá em **Versão > Testes internos**
   - Faça upload do APK
   - Adicione testadores

3. **Instalar no dispositivo**:
   - Os testadores recebem link para download
   - Instale o app do link fornecido
   - Teste as compras (serão simuladas, sem cobrança)

### 3. Verificar Status da Assinatura

```dart
// Verificar se o usuário tem assinatura ativa
final subscriptionProvider = context.read<SubscriptionProvider>();
final hasActive = subscriptionProvider.isPremium;

if (!hasActive) {
  // Redirecionar para tela de assinaturas
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SubscriptionPage()),
  );
}
```

## 🔒 Segurança

### Validação de Compras

O código atual salva as compras localmente. Para produção, recomenda-se:

1. **Validação no Backend** (implementar depois):
```dart
// Em billing_service.dart, método _verifyAndDeliverPurchase
Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchaseDetails) async {
  // Enviar para backend validar
  final response = await http.post(
    Uri.parse('https://seu-backend.com/api/verify-purchase'),
    body: {
      'purchase_token': purchaseDetails.verificationData.serverVerificationData,
      'product_id': purchaseDetails.productID,
    },
  );
  
  // Se válido, liberar acesso
  if (response.statusCode == 200) {
    await _saveSubscriptionLocally(purchaseDetails);
  }
}
```

2. **Verificar periodicamente**:
```dart
// No início do app
await subscriptionProvider.checkSubscriptionStatus();
```

## 🎨 Customização de UI

### Alterar Cores dos Planos

Em `subscription_page.dart`:

```dart
// Card do plano mensal
Container(
  decoration: BoxDecoration(
    color: Colors.blue.withOpacity(0.1), // Sua cor
  ),
)

// Card do plano anual (popular)
Container(
  decoration: BoxDecoration(
    color: Colors.amber.withOpacity(0.1), // Sua cor
  ),
)
```

### Alterar Textos

Em `subscription_plan.dart`:

```dart
static SubscriptionPlan get monthly => SubscriptionPlan(
  name: 'Seu Nome',
  description: 'Sua descrição',
  features: [
    'Recurso 1',
    'Recurso 2',
    // ...
  ],
);
```

## 🚀 Deploy para Produção

### 1. Preparar Build de Produção

```bash
flutter build appbundle --release
```

### 2. Assinar o App

Siga o guia oficial: [Assinando o app](https://docs.flutter.dev/deployment/android#signing-the-app)

### 3. Upload para Play Console

1. Vá em **Versão > Produção**
2. Clique em **Criar nova versão**
3. Faça upload do `.aab` gerado
4. Preencha as notas de versão
5. Revise e lance

### 4. Ativar Faturamento em Produção

1. Configure conta comercial no Play Console
2. Ative as assinaturas
3. Publique o app

## 📊 Métricas Importantes

Monitore no Google Play Console:

- **Taxa de conversão**: Trial → Assinatura paga
- **Taxa de cancelamento**: Quantos cancelam após trial
- **Receita**: MRR (Monthly Recurring Revenue)
- **Usuários ativos premium**

## 🐛 Troubleshooting

### Erro: "Item not available"
- Certifique-se de que as assinaturas estão ativas no Play Console
- Verifique se o app está instalado da Play Store (não via USB)
- Confirme que o ID do produto está correto

### Erro: "Purchase not acknowledged"
- O app não está completando a compra corretamente
- Verifique o método `completePurchase` em `billing_service.dart`

### Trial não funciona
- Verifique se configurou a oferta de trial no Play Console
- Teste com conta que nunca usou o trial antes

### Compra não restaura
- Usuário deve estar logado com mesma conta Google
- Implemente sincronização com backend para melhor experiência

## 📚 Próximos Passos

1. **Backend Laravel** (próxima fase):
   - Validação de compras
   - Sincronização de status
   - Notificações RTDN

2. **Análise de dados**:
   - Firebase Analytics
   - Tracking de conversões
   - A/B testing de preços

3. **Recursos adicionais**:
   - Cupons de desconto
   - Programa de indicação
   - Planos corporativos

## 💡 Dicas

- Ofereça trial de 7 dias para aumentar conversões
- Envie lembretes 3 dias antes da renovação
- Destaque o plano anual com "Economize 17%"
- Permita cancelamento fácil (aumenta confiança)
- Ofereça suporte rápido via chat

## 📞 Suporte

Para dúvidas sobre Google Play Billing:
- [Documentação oficial](https://developer.android.com/google/play/billing)
- [Flutter in_app_purchase](https://pub.dev/packages/in_app_purchase)

---

**Desenvolvido para Wenderliy Fernandes Vasconcelos** - Sistema de Gestão de Serviços para Profissionais de Segurança
