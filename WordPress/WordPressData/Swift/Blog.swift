extension Blog {

    static let jetpackProfessionalYearlyPlanId = 2004
    static let jetpackProfessionalMonthlyPlanId = 2001

    @objc
    public func supports(_ feature: BlogFeature) -> Bool {
        switch feature {
        case .removable:
            return accountIsDefaultAccount
        case .visibility:
            // See -[BlogListViewController fetchRequestPredicateForHideableBlogs]
            // If the logic for this changes that needs to be updated as well
            return accountIsDefaultAccount
        case .people:
            return supportsRestApi() && isListingUsersAllowed()
        case .wpComRESTAPI, .commentLikes:
            return supportsRestApi()
        case .stats:
            return supportsRestApi() && isViewingStatsAllowed()
        case .stockPhotos:
            // FIXME: JetpackFeaturesRemovalCoordinator not available yet
//            return supportsRestApi() && JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()
            return supportsRestApi()
        case .tenor:
            // FIXME: JetpackFeaturesRemovalCoordinator not available yet
//            return JetpackFeaturesRemovalCoordinator.jetpackFeaturesEnabled()
            fatalError()
        case .sharing:
            return supportsSharing
        case .oAuth2Login:
            return isHostedAtWPcom
        case .mentions, .xposts:
            return isAccessibleThroughWPCom()
        case .reblog, .plans:
            return isHostedAtWPcom && isAdmin
        case .pluginManagement:
            return supportsPluginManagement && isAdmin
        case .jetpackImageSettings:
            return supportsJetpackImageSettings()
        case .jetpackSettings:
            return supportsJetpackSettings()
        case .pushNotifications:
            return supportsPushNotifications
        case .themeBrowsing:
            return supportsRestApi() && isAdmin
        case .activity:
            return supportsRestApi() && isAdmin
        case .customThemes:
            return supportsRestApi() && isAdmin && !isHostedAtWPcom
        case .premiumThemes:
            guard supports(.customThemes) else { return false }
            guard let planID else { return false }

            return planID.intValue == Blog.jetpackProfessionalYearlyPlanId || planID.intValue == Blog.jetpackProfessionalMonthlyPlanId
        case .menus:
            return supportsRestApi() && isAdmin
        case .private:
            return isHostedAtWPcom
        case .siteManagement:
            return supportsSiteManagementServices()
        case .domains:
            return (isHostedAtWPcom || isAtomic()) && isAdmin && !isWPForTeams()
        case .noncePreviews:
            return supportsRestApi() && !isHostedAtWPcom
        case .mediaMetadataEditing:
            return isAdmin
        case .mediaAltEditing:
            // See:
            // - https://core.trac.wordpress.org/ticket/58582
            // - https://github.com/wordpress-mobile/WordPress-Android/issues/18514#issuecomment-1589752274
            return supportsRestApi()
        case .mediaDeletion:
            return isAdmin
        case .homepageSettings:
            return supportsRestApi() && isAdmin
        case .contactInfo:
            return hasRequiredWordPressVersion("5.6")
        case .blockEditorSettings:
            return supportsBlockEditorSettings()
        case .layoutGrid:
            return isHostedAtWPcom || isAtomic()
        case .tiledGallery:
            return isHostedAtWPcom
        case .videoPress:
            return isHostedAtWPcom
        case .videoPressV5:
            return isHostedAtWPcom && isAtomic() && hasRequiredWordPressVersion("5.8")
        case .facebookEmbed:
            return supportsEmbedVariation("9.0")
        case .instagramEmbed:
            return supportsEmbedVariation("9.0")
        case .loomEmbed:
            return supportsEmbedVariation("9.0")
        case .smartframeEmbed:
            return supportsEmbedVariation("10.2")
        case .fileDownloadsStats:
            return isHostedAtWPcom
        case .blaze:
            return canBlaze
        case .pages:
            return isListingPagesAllowed()
        case .siteMonitoring:
            return isAdmin && isAtomic()
        @unknown default:
            fatalError()
        }
    }

    @objc
    public func supportsPublicize() -> Bool {
        guard supports(.wpComRESTAPI) else { return false }
        guard isPublishingPostsAllowed() else { return false }

        if isHostedAtWPcom {
            return !((getOptionValue(OptionsKeys.publicizeDisabled) as? Bool) ?? true)
        } else {
            return isJetpackModuleActive(name: ModuleKeys.publicize)
        }
    }

    private var accountIsDefaultAccount: Bool {
        account?.isDefaultWordPressComAccount ?? false
    }

    private var supportsPushNotifications: Bool {
        accountIsDefaultAccount
    }

    private func hasRequiredJetpackVersion(_ version: String) -> Bool {
        guard let jetpackVersion = jetpack?.version else { return false }

        return supportsRestApi()
        && !isHostedAtWPcom
        && jetpackVersion.compare(version, options: .numeric) != .orderedAscending
    }

    private func supportsEmbedVariation(_ variation: String) -> Bool {
        hasRequiredJetpackVersion(variation) || isHostedAtWPcom
    }

    private var supportsSharing: Bool {
        supportsPublicize() || supportsShareButtons()
    }

    private func supportsShareButtons() -> Bool {
        guard isAdmin else { return false }
        guard supports(.wpComRESTAPI) else { return false }

        return isHostedAtWPcom ? true : jetpackSharingButtonsModuleEnabled()
    }

    private var supportsPluginManagement: Bool {
        let isTransferrable = isHostedAtWPcom && hasBusinessPlan && siteVisibility != .private

        var supports = isTransferrable || hasRequiredJetpackVersion("5.6")

        // If the site is not hosted on WP.com we can still manage plugins directly using the WP.org rest API
        // Reference: https://make.wordpress.org/core/2020/07/16/new-and-modified-rest-api-endpoints-in-wordpress-5-5/
        if (supports == false) && (account == nil) {
            supports = !isHostedAtWPcom && (selfHostedSiteRestApi != nil) && hasRequiredWordPressVersion("5.5")
        }

        return supports
    }

    private func isJetpackModuleActive(name: String) -> Bool {
        let activeModules = getOptionValue(OptionsKeys.activeModules) as? [String] ?? []
        return activeModules.contains(name)
    }

    private struct OptionsKeys {
        static let activeModules = ""
        static let publicizeDisabled = "publicize_permanently_disabled"
    }

    private struct ModuleKeys {
        static let publicize = "publicize"
    }
}
