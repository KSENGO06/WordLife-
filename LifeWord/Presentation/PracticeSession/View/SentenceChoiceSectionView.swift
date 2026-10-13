import SwiftUI

struct SentenceChoiceExerciseView: View {
    let exercise: SentenceChoiceExercise
    let audioPlayer: AudioPlayer
    let onAnswer: (Bool) -> Void
 
    @State private var options: [SentenceChoiceOption] = []
    @State private var selected: Set<String> = []
    @State private var isChecked = false
 
    private var correctIds: Set<String> {
        Set(exercise.options.filter { $0.isCorrect }.map { $0.id })
    }
    private var isAnswerCorrect: Bool { selected == correctIds }
 
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ExerciseTitleLabel(text: "Select 2 correct sentences")
                Spacer()
            }
 
            VStack(spacing: 12) {
                ForEach(options) { option in
                    Button {
                        guard !isChecked else { return }
                        if selected.contains(option.id) {
                            selected.remove(option.id)
                        } else {
                            selected.insert(option.id)
                        }
                    } label: {
                        HStack {
                            Text(option.text)
                                .font(AppFont.interMedium(17))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding()
                        .background(optionColor(for: option))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isChecked)
                }
            }
            .padding(.horizontal)
            .padding(.top, 48)
 
            if isChecked {
                VStack(alignment: .leading, spacing: 10) {
                    Text(isAnswerCorrect ? "Correct!" : "Incorrect")
                        .font(.appHeadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    ForEach(exercise.options.filter { $0.isCorrect }) { option in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.text).font(.appHeadline)
                            Text(option.translation).font(.appBodyRegular).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((isAnswerCorrect ? Color.appCorrect : Color.appIncorrect).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
 
            Spacer()
 
            Button(isChecked ? "Continue" : "Check") {
                if isChecked {
                    onAnswer(isAnswerCorrect)
                } else {
                    isChecked = true
                }
            }
            .disabled(selected.count != 2)
            .buttonStyle(.primary)
            .padding(.horizontal)
        }
        .onAppear {
            options = exercise.options.shuffled()
        }
    }
 
    private func optionColor(for option: SentenceChoiceOption) -> Color {
        guard isChecked else {
            return selected.contains(option.id) ? Color.appAccent : Color.appAccent.opacity(0.75)
        }
        return option.isCorrect ? Color.appCorrect : Color.appIncorrect
    }
}
 
