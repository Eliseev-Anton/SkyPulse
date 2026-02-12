import Foundation
import RxSwift
import RxCocoa
import RxFlow
import RxRelay

/// ViewModel экрана настроек: уведомления, кэш, информация.
final class SettingsViewModel: ViewModelType, Stepper {

    let steps = PublishRelay<Step>()

    /// Модель элемента настроек
    struct SettingsItem {
        let title: String
        let subtitle: String?
        let icon: String
        let type: ItemType

        enum ItemType {
            case notifications
            case clearCache
            case about
        }
    }

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<SettingsItem>
        let notificationToggled: Observable<Bool>
    }

    struct Output {
        let sections: Driver<[[SettingsItem]]>
        let notificationsEnabled: Driver<Bool>
        let cacheSize: Driver<String>
    }

    private let realmManager: RealmManager
    private let disposeBag = DisposeBag()

    init(realmManager: RealmManager) {
        self.realmManager = realmManager
    }

    func transform(input: Input) -> Output {
        let notificationsEnabled = BehaviorRelay<Bool>(value: false)
        let cacheSize = BehaviorRelay<String>(value: "—")

        // Построение секций
        let sections: [[SettingsItem]] = [
            // Секция 1: Основные
            [
                SettingsItem(
                    title: NSLocalizedString("settings.notifications", comment: ""),
                    subtitle: NSLocalizedString("settings.notifications.subtitle", comment: ""),
                    icon: "bell",
                    type: .notifications
                )
            ],
            // Секция 2: Данные
            [
                SettingsItem(
                    title: NSLocalizedString("settings.clearCache", comment: ""),
                    subtitle: nil,
                    icon: "trash",
                    type: .clearCache
                )
            ],
            // Секция 3: Информация
            [
                SettingsItem(
                    title: NSLocalizedString("settings.about", comment: ""),
                    subtitle: "SkyPulse v1.0",
                    icon: "info.circle",
                    type: .about
                )
            ]
        ]

        // Обработка выбора элемента
        input.itemSelected
            .subscribe(onNext: { [weak self] item in
                switch item.type {
                case .clearCache:
                    self?.realmManager.clearAll()
                    cacheSize.accept(NSLocalizedString("settings.cacheCleared", comment: ""))
                case .notifications, .about:
                    break
                }
            })
            .disposed(by: disposeBag)

        // Переключение уведомлений
        input.notificationToggled
            .bind(to: notificationsEnabled)
            .disposed(by: disposeBag)

        // Расчёт размера кэша
        input.viewDidLoad
            .subscribe(onNext: {
                let size = Self.calculateRealmFileSize()
                cacheSize.accept(size)
            })
            .disposed(by: disposeBag)

        return Output(
            sections: .just(sections),
            notificationsEnabled: notificationsEnabled.asDriver(),
            cacheSize: cacheSize.asDriver()
        )
    }

    // MARK: - Размер файла Realm

    private static func calculateRealmFileSize() -> String {
        guard let realmURL = Realm.Configuration.defaultConfiguration.fileURL else {
            return "—"
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: realmURL.path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            Logger.error("Ошибка получения размера Realm", error: error)
        }
        return "—"
    }
}

// Realm import для доступа к Configuration
import RealmSwift
