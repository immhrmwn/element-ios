/*
Copyright 2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import UIKit
import MatrixSDK

/// Factory to create StorageManagementViewController for ObjC callers
@objc(StorageManagementViewControllerFactory)
@objcMembers
final class StorageManagementViewControllerFactory: NSObject {
    @objc static func createViewController() -> UIViewController {
        StorageManagementViewController(style: .insetGrouped)
    }
}

final class StorageManagementViewController: UITableViewController, Themable {
    
    private enum Section: Int, CaseIterable {
        case usage = 0
        case keepMessages = 1
        case manualDelete = 2
    }
    
    private var totalSizeString: String?
    private var isClearing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = VectorL10n.screenStorageManagementTitle
        tableView.register(TableViewCellWithCheckBoxAndLabel.nib(), forCellReuseIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier())
        tableView.register(MXKTableViewCellWithButton.self, forCellReuseIdentifier: MXKTableViewCellWithButton.defaultReuseIdentifier())
        registerThemeServiceDidChangeThemeNotification()
        update(theme: ThemeService.shared().theme)
        loadStorageSizes()
    }
    
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        update(theme: ThemeService.shared().theme)
    }
    
    func update(theme: Theme) {
        view.backgroundColor = theme.backgroundColor
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.lineBreakColor
        tableView.reloadData()
    }
    
    // MARK: - Storage calculation
    
    private func loadStorageSizes() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var total: Int64 = 0
            
            // Media cache
            if let mediaPath = MXMediaManager.getCachePath(), !mediaPath.isEmpty {
                let size = MXTools.folderSize(mediaPath)
                total += size
            }
            
            // App group container (store, etc.)
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BuildSettings.applicationGroupIdentifier) {
                total += self?.directorySize(at: containerURL) ?? 0
            }
            
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            let formatted = formatter.string(fromByteCount: total)
            
            DispatchQueue.main.async {
                self?.totalSizeString = formatted
                self?.tableView.reloadData()
            }
        }
    }
    
    private func directorySize(at url: URL) -> Int64 {
        var size: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let attrs = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = attrs.fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }
    
    // MARK: - Clear cache
    
    private func presentClearCacheAlert() {
        let alert = UIAlertController(
            title: VectorL10n.screenStorageManagementClearCacheAlertTitle,
            message: VectorL10n.screenStorageManagementClearCacheAlertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: VectorL10n.screenStorageManagementClearCacheAlertClear, style: .destructive) { [weak self] _ in
            self?.clearCacheNow()
        })
        present(alert, animated: true)
    }
    
    private func clearCacheNow() {
        guard !isClearing else { return }
        isClearing = true
        tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AppDelegate.theDelegate().reloadMatrixSessions(true)
            RiotSettings.shared.lastLocalCacheCleanupTimestamp = Date().timeIntervalSince1970
            self.isClearing = false
            self.loadStorageSizes()
            self.tableView.reloadData()
            self.showSuccessToast(VectorL10n.screenStorageManagementDeleteSuccess)
        }
    }
    
    private func showSuccessToast(_ message: String) {
        // Simple toast - Element uses NotificationBanner or similar
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            alert.dismiss(animated: true)
        }
    }
    
    // MARK: - Table view
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .usage: return 1
        case .keepMessages: return RiotSettings.KeepMessagesFor.allCases.count + 1 // +1 for label row
        case .manualDelete: return 1
        case .none: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .usage: return VectorL10n.screenStorageManagementUsageHeader
        case .keepMessages: return VectorL10n.screenStorageManagementKeepMessagesHeader
        case .manualDelete: return VectorL10n.screenStorageManagementManualHeader
        case .none: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .keepMessages: return VectorL10n.screenStorageManagementKeepMessagesFooter
        case .manualDelete: return VectorL10n.screenStorageManagementManualFooter
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let theme = ThemeService.shared().theme
        
        switch Section(rawValue: indexPath.section) {
        case .usage:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UsageCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "UsageCell")
            cell.textLabel?.text = VectorL10n.screenStorageManagementUsedByApp
            cell.detailTextLabel?.text = totalSizeString ?? VectorL10n.screenStorageManagementLoading
            cell.textLabel?.textColor = theme.textPrimaryColor
            cell.detailTextLabel?.textColor = theme.textSecondaryColor
            cell.backgroundColor = theme.backgroundColor
            cell.selectionStyle = .none
            return cell
            
        case .keepMessages:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LabelCell") ?? UITableViewCell(style: .default, reuseIdentifier: "LabelCell")
                cell.textLabel?.text = VectorL10n.screenStorageManagementKeepMessagesForLabel
                cell.textLabel?.textColor = theme.textSecondaryColor
                cell.backgroundColor = theme.backgroundColor
                cell.selectionStyle = .none
                return cell
            }
            let option = RiotSettings.KeepMessagesFor.allCases[indexPath.row - 1]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellWithCheckBoxAndLabel.defaultReuseIdentifier(), for: indexPath) as? TableViewCellWithCheckBoxAndLabel else {
                return UITableViewCell()
            }
            cell.label.text = titleForKeepMessagesOption(option)
            cell.isEnabled = RiotSettings.shared.keepMessagesFor == option
            cell.backgroundColor = theme.backgroundColor
            return cell
            
        case .manualDelete:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MXKTableViewCellWithButton.defaultReuseIdentifier(), for: indexPath) as? MXKTableViewCellWithButton else {
                return UITableViewCell()
            }
            cell.mxkButton.setTitle(VectorL10n.screenStorageManagementDeleteNowButton, for: .normal)
            cell.mxkButton.setTitle(VectorL10n.screenStorageManagementDeleteNowButton, for: .highlighted)
            cell.mxkButton.setTitleColor(theme.tintColor, for: .normal)
            cell.mxkButton.setTitleColor(theme.tintColor.withAlphaComponent(0.6), for: .disabled)
            cell.mxkButton.titleLabel?.font = .systemFont(ofSize: 17)
            cell.mxkButton.backgroundColor = .clear
            cell.mxkButton.layer.cornerRadius = 16
            cell.mxkButton.layer.borderWidth = 2
            let borderColor = isClearing ? theme.tintColor.withAlphaComponent(0.4) : theme.tintColor
            cell.mxkButton.layer.borderColor = borderColor.cgColor
            // Full width
            cell.mxkButton.translatesAutoresizingMaskIntoConstraints = false
            let padding = tableView.vc_separatorInset.left
            NSLayoutConstraint.deactivate(cell.contentView.constraints.filter {
                ($0.firstItem as? UIView) === cell.mxkButton || ($0.secondItem as? UIView) === cell.mxkButton
            })
            NSLayoutConstraint.activate([
                cell.mxkButton.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: padding),
                cell.mxkButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -padding),
                cell.mxkButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
                cell.mxkButton.heightAnchor.constraint(equalToConstant: 48)
            ])
            cell.mxkButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.mxkButton.addTarget(self, action: #selector(clearCacheTapped), for: .touchUpInside)
            cell.mxkButton.isEnabled = !isClearing
            if isClearing {
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.startAnimating()
                cell.accessoryView = spinner
            } else {
                cell.accessoryView = nil
            }
            return cell
            
        case .none:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Section(rawValue: indexPath.section) == .keepMessages, indexPath.row > 0 else { return }
        let option = RiotSettings.KeepMessagesFor.allCases[indexPath.row - 1]
        RiotSettings.shared.keepMessagesFor = option
        tableView.reloadSections(IndexSet(integer: Section.keepMessages.rawValue), with: .none)
    }
    
    private func titleForKeepMessagesOption(_ option: RiotSettings.KeepMessagesFor) -> String {
        switch option {
        case .forever: return VectorL10n.screenStorageManagementKeepForever
        case .oneWeek: return VectorL10n.screenStorageManagementKeepOneWeek
        case .oneMonth: return VectorL10n.screenStorageManagementKeepOneMonth
        case .threeMonths: return VectorL10n.screenStorageManagementKeepThreeMonths
        case .sixMonths: return VectorL10n.screenStorageManagementKeepSixMonths
        case .oneYear: return VectorL10n.screenStorageManagementKeepOneYear
        }
    }
    
    @objc private func clearCacheTapped() {
        presentClearCacheAlert()
    }
}
