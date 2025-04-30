// lib/graphql/mutations/auth_mutations.dart
class AuthMutations {
  // Mutation per il login
  static String login = r'''
    mutation Login($input: LoginInput!) {
      login(input: $input) {
        token
      }
    }
  ''';

  // Mutation per la registrazione
  static String register = r'''
    mutation Register($input: RegisterInput!) {
      register(input: $input) {
        token
      }
    }
  ''';

  // Mutation per il recupero password
  static String forgotPassword = r'''
    mutation PasswordRecovery($input: PasswordRecoveryInput!) {
      passwordRecovery(input: $input) {
        success
      }
    }
  ''';

  // Mutation per l'eliminazione dell'account
  static String deleteAccount = r'''
    mutation DeleteAccount($input: DeleteAccountInput!) {
      deleteAccount(input: $input) {
        success
      }
    }
  ''';
}