// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Shared
import BraveShared
import BraveUI
import Data

extension PrivacyReportsView {
  struct PrivacyHubLastWeekSection: View {
    @State private var mostFrequentTracker: CountableEntity?
    @State private var riskiestWebsite: CountableEntity?
    
    @State private var mostFrequentTrackerLoading = true
    @State private var riskiestWebsiteLoading = true
    
    private var noData: Bool {
      return mostFrequentTracker == nil && riskiestWebsite == nil
    }
    
    private var noDataCalloutView: some View {
      HStack {
        Image(systemName: "info.circle.fill")
        Text(Strings.PrivacyHub.noDataCalloutBody)
      }
      .foregroundColor(Color.white)
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color(.braveInfoLabel))
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        if noData {
          noDataCalloutView
        }
        
        Text(Strings.PrivacyHub.lastWeekHeader.uppercased())
          .font(.footnote.weight(.medium))
          .fixedSize(horizontal: false, vertical: true)
        
        HStack {
          Image("frequent_tracker", bundle: .current)
            .unredacted()
          VStack(alignment: .leading) {
            Text(Strings.PrivacyHub.mostFrequentTrackerAndAdTitle.uppercased())
              .font(.caption)
              .foregroundColor(.init(.secondaryBraveLabel))
              .unredacted()
            if let mostFrequentTracker = mostFrequentTracker {
              Text(
                markdown: String.localizedStringWithFormat(Strings.PrivacyHub.mostFrequentTrackerAndAdBody,
                                                           mostFrequentTracker.name, mostFrequentTracker.count)
              )
              .font(.callout)
            } else {
              Text(Strings.PrivacyHub.noDataToShow)
                .foregroundColor(.init(.secondaryBraveLabel))
            }
          }
          Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.braveBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .redacted(reason: mostFrequentTrackerLoading ? .placeholder: [])
        
        HStack {
          Image("creepy_website", bundle: .current)
            .unredacted()
          VStack(alignment: .leading) {
            Text(Strings.PrivacyHub.riskiestWebsiteTitle.uppercased())
              .font(.caption)
              .foregroundColor(Color(.secondaryBraveLabel))
              .unredacted()
            
            if let riskiestWebsite = riskiestWebsite {
              Text(
                markdown: String.localizedStringWithFormat(Strings.PrivacyHub.riskiestWebsiteBody,
                                                           riskiestWebsite.name, riskiestWebsite.count)
              )
              .font(.callout)
            } else {
              Text(Strings.PrivacyHub.noDataToShow)
                .foregroundColor(Color(.secondaryBraveLabel))
            }
          }
          
          Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.braveBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .redacted(reason: riskiestWebsiteLoading ? .placeholder: [])
      }
      .fixedSize(horizontal: false, vertical: true)
      .onAppear {
        BlockedResource.mostBlockedTracker(inLastDays: 7) { result in
          mostFrequentTracker = result
          mostFrequentTrackerLoading = false
        }
        
        BlockedResource.riskiestWebsite(inLastDays: 7) { result in
          riskiestWebsite = result
          riskiestWebsiteLoading = false
        }
      }
    }
  }
}

#if DEBUG
struct PrivacyHubLastWeekSection_Previews: PreviewProvider {
  static var previews: some View {
    PrivacyReportsView.PrivacyHubLastWeekSection()
  }
}
#endif
