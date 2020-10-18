// Использовать для того, чтобы объявлять static properties с различными стилями.
// Это нужно, для того, чтобы при применении стиля можно было написать что-то вроде `view.apply(style: .yourStyle)`

import SurfUtils

extension UIStyle {
    static var card: UIStyle<UIView> {
        return ViewStyle(backgroundColor: Asset.Color.black50.color, cornerRadius: 24.0)
    }

    static var separator: UIStyle<UIView> {
        return ViewStyle(backgroundColor: Asset.Color.black05.color, cornerRadius: .zero)
    }
}
