import SwiftUI

struct ContentView: View {
    static let fileURLType = kUTTypeFileURL as String
    @ObservedObject var conversionHandler = ConversionHandler()

    var labelText: String {
        switch conversionHandler.state {
        case .waiting:
            return "Drop FLAC here"
        case .converting(filename: let filename):
            return "Converting \(filename)"
        case .error(let error):
            return error.localizedDescription
        case .finished:
            return "Done"
        }
    }

    var activityView: AnyView {
        if case .converting = conversionHandler.state {
            return AnyView(
                ActivityIndicator()
                    .frame(width: 50)
                    .foregroundColor(.white)
            )
        }
        return AnyView(EmptyView())
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [.pink, .purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .opacity(0.7)
                .onDrop(of: [Self.fileURLType], delegate: self)
            VStack {
                Text(labelText)
                    .font(.system(size: 20, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                self.activityView
            }
            .padding()
        }
        .edgesIgnoringSafeArea(.all)
        .frame(width: 300, height: 200)
    }
}

extension ContentView: DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [Self.fileURLType]).first else { return false }
        itemProvider.loadItem(forTypeIdentifier: Self.fileURLType, options: nil) { item, error in
            guard
                let data = item as? Data,
                let fileURL = URL(dataRepresentation: data, relativeTo: nil)
            else {
                return
            }
            self.conversionHandler.run(withFile: fileURL)
        }
        return true
    }
}

//struct ProgressView: View {
//    @Binding var progress: CGFloat
//
//    var body: some View {
//        Circle()
//            .trim(from: 0.0, to: progress)
//            .stroke(lineWidth: 10)
//            .foregroundColor(.blue)
//            .opacity(0.3)
//            .animation(.easeIn)
//    }
//}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
