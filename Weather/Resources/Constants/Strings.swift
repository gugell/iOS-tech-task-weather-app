// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
public enum L10n {

  public enum Common {
    public enum Button {
      /// Повторить
      public static let `repeat` = L10n.tr("Localizable", "Common.Button.repeat")
    }
    public enum TextField {
      /// Город или индекс
      public static let search = L10n.tr("Localizable", "Common.TextField.search")
    }
  }

  public enum Empty {
    /// Не выбран ни один город для просмотра прогноза
    public static let cities = L10n.tr("Localizable", "Empty.cities")
    /// Ничего не удалось найти. Попробуйте изменить запрос
    public static let request = L10n.tr("Localizable", "Empty.request")
  }

  public enum Error {
    /// Отсутствует соединение с интернетом. Попробуйте позже
    public static let noInternetConnection = L10n.tr("Localizable", "Error.noInternetConnection")
    /// Что-то пошло не так. Не удалось загрузить данные
    public static let notDefined = L10n.tr("Localizable", "Error.notDefined")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
