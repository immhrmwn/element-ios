// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class RoomInviteViewController: ContactsTableViewController {
    
    var room: MXRoom?
    private var roomAlias: String?
    private var joinRule: MXRoomJoinRule?
    
    private lazy var shareLinkPresenter: ShareInviteLinkPresenter = ShareInviteLinkPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomAlias = room?.summary?.aliases?.first
        joinRule = MXRoomJoinRule(identifier: room?.summary?.joinRule)
        setupShareInviteLinkHeader()
    }
    
    private func setupShareInviteLinkHeader() {
        guard roomAlias != nil,
              RiotSettings.shared.allowInviteExernalUsers,
              joinRule != .invite,
              joinRule != .restricted else {
            contactsTableView.tableHeaderView = nil
            return
        }
        
        let inviteHeaderView = ShareInviteLinkHeaderView.instantiate()
        inviteHeaderView.delegate = self
        contactsTableView.tableHeaderView = inviteHeaderView
    }
    
    private func showInviteLink(from sourceView: UIView?) {
        guard let room = room else {
            return
        }
        shareLinkPresenter.present(for: room, from: self, sourceView: sourceView, animated: true)
    }
}

// MARK: - ShareInviteLinkHeaderViewDelegate
extension RoomInviteViewController: ShareInviteLinkHeaderViewDelegate {
    func shareInviteLinkHeaderView(_ headerView: ShareInviteLinkHeaderView, didTapButton button: UIButton) {
        showInviteLink(from: button)
    }
}

// MARK: - UISearchBarDelegate (Suggestions-only)

extension RoomInviteViewController {
    
    override func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Mirror the Start Chat behaviour: only filter the in‑memory Suggestions
        // section (recent DM contacts), without hitting the homeserver user
        // directory.
        filterSuggestionsOnly(withSearchText: searchText)
    }
    
    override func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Keep the original behaviour from ContactsTableViewController:
        // reset generic filtering and close the invite screen.
        super.searchBarCancelButtonClicked(searchBar)
        // Also reset local Suggestions filtering.
        filterSuggestionsOnly(withSearchText: nil)
    }
}
