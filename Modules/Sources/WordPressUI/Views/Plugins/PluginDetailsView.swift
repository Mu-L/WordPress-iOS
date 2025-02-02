import SwiftUI

struct Plugin {
    let name: String
    let description: String
    let version: String
    let author: String
    let rating: Double
    let totalRatings: Int
    let lastUpdated: Date
    
    let iconUrl: URL
    let imageUrl: URL
    
    var lastUpdatedString: String {
        RelativeDateTimeFormatter().string(for: lastUpdated) ?? lastUpdated.formatted()
    }
}

struct RatingView: View {
    let rating: Double
    let maxRating: Int = 5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
            Text(String(format: "%.1f", rating))
                .foregroundColor(.secondary)
        }
    }
}

struct PluginFactView: View {
    let key: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value).font(.body)
        }
    }
}

struct WordPressPluginDetailView: View {
    let plugin: Plugin
    
    var body: some View {
        ScrollView {
            // Header Image
            AsyncImage(url: plugin.imageUrl){ result in
                result.image?
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea(.all)
                    .frame(maxHeight: 300)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                HStack(alignment: .top) {
                    AsyncImage(url: plugin.iconUrl){ result in
                        result.image?
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 100)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(plugin.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .lineLimit(3, reservesSpace: false)
                        
                        RatingView(rating: plugin.rating)
                        Text("(\(plugin.totalRatings) ratings)")
                            .foregroundColor(.secondary)
                    }
                }.padding(.horizontal)
                
                // Version and Author
                VStack(alignment: .leading, spacing: 12) {
                    PluginFactView(key: "Version", value: plugin.version)
                    PluginFactView(key: "Last Updated", value: plugin.lastUpdatedString)
                    PluginFactView(key: "Author", value: plugin.author)
                    PluginFactView(key: "Description", value: plugin.description)
                }
                .padding(.horizontal)

                // Navigation Section
                VStack(spacing: 24.0){
                    NavigationLink {
                        Text("HERE")
                    } label: {
                        Text("Plugin Details")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.primary)
                    }.foregroundStyle(.primary)
                    
                    NavigationLink {
                        Text("HERE")
                    } label: {
                        Text("Reviews")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.primary)
                    }.foregroundStyle(.primary)

                    NavigationLink {
                        Text("HERE")
                    } label: {
                        Text("Installation")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.primary)
                    }.foregroundStyle(.primary)

                    NavigationLink {
                        Text("HERE")
                    } label: {
                        Text("Development")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.primary)
                    }.foregroundStyle(.primary)
                }.padding(.horizontal)
            }
        }
    }
}

#Preview {
    NavigationView {
        WordPressPluginDetailView(plugin: Plugin(
            name: "WooCommerce",
            description: "An eCommerce toolkit that helps you sell anything. Beautifully.",
            version: "7.9.0",
            author: "Automattic",
            rating: 4.5,
            totalRatings: 1250,
            lastUpdated: Date(timeIntervalSince1970: 1731465000),
            iconUrl: URL(string: "https://ps.w.org/woocommerce/assets/icon-256x256.gif?rev=2869506")!,
            imageUrl: URL(string: "https://ps.w.org/woocommerce/assets/banner-1544x500.png?rev=3000842")!
        ))
    }
}

