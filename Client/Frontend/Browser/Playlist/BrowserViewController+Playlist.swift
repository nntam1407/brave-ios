// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Data
import Shared
import BraveShared
import BraveUI

private let log = Logger.browserLogger

extension BrowserViewController: PlaylistHelperDelegate {
    
    func updatePlaylistURLBar(tab: Tab?, state: PlaylistItemAddedState, item: PlaylistInfo?) {
        openInPlayListActivity(info: state == .existingItem ? item : nil)
        addToPlayListActivity(info: state == .newItem ? item : nil, itemDetected: state == .newItem)
        
        switch state {
        case .none:
            topToolbar.menuButton.removeBadge(.playlist, animated: true)
            toolbar?.menuButton.removeBadge(.playlist, animated: true)
        case .newItem, .existingItem:
            topToolbar.menuButton.addBadge(.playlist, animated: true)
            toolbar?.menuButton.addBadge(.playlist, animated: true)
        }
        
        if let tab = tab, tab === tabManager.selectedTab {
            tab.playlistItemState = state
            tab.playlistItem = item
            
            let shouldShowPlaylistURLBarButton = tab.url?.isPlaylistSupportedSiteURL ?? false
            let playlistButton = topToolbar.locationView.playlistButton
            switch state {
            case .none:
                playlistButton.buttonState = .none
            case .newItem:
                playlistButton.buttonState = shouldShowPlaylistURLBarButton ? .addToPlaylist : .none
            case .existingItem:
                playlistButton.buttonState = shouldShowPlaylistURLBarButton ? .addedToPlaylist : .none
            }
        } else {
            topToolbar.locationView.playlistButton.buttonState = .none
            topToolbar.menuButton.removeBadge(.playlist, animated: true)
            toolbar?.menuButton.removeBadge(.playlist, animated: true)
        }
    }
    
    func showPlaylistPopover(tab: Tab?, state: PlaylistPopoverState) {
        guard Preferences.Playlist.showToastForAdd.value,
              let selectedTab = tabManager.selectedTab else {
            return
        }
        
        if state == .addToPlaylist {
            if Preferences.Playlist.showAddToPlaylistURLBarOnboarding.value {
                Preferences.Playlist.showAddToPlaylistURLBarOnboarding.value = false
            } else {
                if let item = selectedTab.playlistItem {
                    UIImpactFeedbackGenerator(style: .medium).bzzt()
                    
                    // Update playlist with new items.
                    self.addToPlaylist(item: item) { [weak self] didAddItem in
                        guard let self = self else { return }
                        
                        if didAddItem {
                            self.updatePlaylistURLBar(tab: tab, state: .existingItem, item: item)
                        }
                    }
                }
                return
            }
        }
        
        let popover = PopoverController(contentController: PlaylistPopoverViewController(state: state).then {
            $0.rootView.onPrimaryButtonPressed = { [weak self] in
                guard let self = self,
                      let item = selectedTab.playlistItem else { return }
                
                switch state {
                case .addToPlaylist:
                    // Dismiss popover
                    UIImpactFeedbackGenerator(style: .medium).bzzt()
                    self.dismiss(animated: true, completion: nil)
                    
                    // Update playlist with new items.
                    self.addToPlaylist(item: item) { [weak self] didAddItem in
                        guard let self = self else { return }
                        
                        if didAddItem {
                            self.updatePlaylistURLBar(tab: tab, state: .existingItem, item: item)
                        }
                    }
                    
                case .addedToPlaylist:
                    // Dismiss popover
                    UIImpactFeedbackGenerator(style: .medium).bzzt()
                    
                    self.dismiss(animated: true) {
                        DispatchQueue.main.async {
                            if let webView = tab?.webView {
                                PlaylistHelper.getCurrentTime(webView: webView, nodeTag: item.tagId) { [weak self] currentTime in
                                    self?.openPlaylist(item: item, playbackOffset: currentTime)
                                }
                            } else {
                                self.openPlaylist(item: item, playbackOffset: 0.0)
                            }
                        }
                    }
                }
            }
            
            $0.rootView.onSecondaryButtonPressed = {
                guard let item = selectedTab.playlistItem else { return }
                UIImpactFeedbackGenerator(style: .medium).bzzt()
                
                self.dismiss(animated: true) {
                    DispatchQueue.main.async {
                        if PlaylistManager.shared.delete(item: item) {
                            self.updatePlaylistURLBar(tab: tab, state: .newItem, item: item)
                        }
                    }
                }
            }
        })
        popover.present(from: topToolbar.locationView.playlistButton, on: self)
    }
    
    func openPlaylist(item: PlaylistInfo?, playbackOffset: Double) {
        let isRestoredController = (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController != nil
        
        let playlistController = (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController as? PlaylistViewController ?? PlaylistViewController()
        playlistController.modalPresentationStyle = .fullScreen
        
        playlistController.initialItem = item
        playlistController.initialItemPlaybackOffset = playbackOffset
        
        /// Donate Open Playlist Activity for suggestions
        let openPlaylist = ActivityShortcutManager.shared.createShortcutActivity(type: .openPlayList)
        self.userActivity = openPlaylist
        openPlaylist.becomeCurrent()

        present(playlistController, animated: true) {
            if isRestoredController {
                playlistController.initiatePlaybackOfLastPlayedItem()
            }
        }
    }
    
    func addToPlayListActivity(info: PlaylistInfo?, itemDetected: Bool) {
        if info == nil {
            addToPlayListActivityItem = nil
        } else {
            addToPlayListActivityItem = (enabled: itemDetected, item: info)
        }
    }
    
    func openInPlayListActivity(info: PlaylistInfo?) {
        if info == nil {
            openInPlaylistActivityItem = nil
        } else {
            openInPlaylistActivityItem = (enabled: true, item: info)
        }
    }
    
    func addToPlaylist(item: PlaylistInfo, completion: ((_ didAddItem: Bool) -> Void)?) {
        if PlaylistManager.shared.isDiskSpaceEncumbered() {
            let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet
            let alert = UIAlertController(
                title: Strings.PlayList.playlistDiskSpaceWarningTitle, message: Strings.PlayList.playlistDiskSpaceWarningMessage, preferredStyle: style)
            
            alert.addAction(UIAlertAction(title: Strings.OKString, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                self.openInPlaylistActivityItem = (enabled: true, item: item)
                self.addToPlayListActivityItem = nil
                
                PlaylistItem.addItem(item, cachedData: nil) {
                    PlaylistManager.shared.autoDownload(item: item)
                    completion?(true)
                }
            }))
            
            alert.addAction(UIAlertAction(title: Strings.CancelString, style: .cancel, handler: { _ in
                completion?(false)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            openInPlaylistActivityItem = (enabled: true, item: item)
            addToPlayListActivityItem = nil
            
            PlaylistItem.addItem(item, cachedData: nil) {
                PlaylistManager.shared.autoDownload(item: item)
                completion?(true)
            }
        }
    }
    
    func openInPlaylist(item: PlaylistInfo, completion: (() -> Void)?) {
        let playlistController = (UIApplication.shared.delegate as? AppDelegate)?.playlistRestorationController ?? PlaylistViewController()
        playlistController.modalPresentationStyle = .fullScreen
        present(playlistController, animated: true) {
            completion?()
        }
    }
}
