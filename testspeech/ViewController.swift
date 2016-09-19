import UIKit

import Speech

class ViewController: UIViewController  {
    @IBOutlet weak var console: UITextView!
    
    var previousText: String? = nil
    
    var currentUUID: UUID? = nil
    
    let speechEngine = SpeechEngine()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.speechEngine.delegate = self
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
}

extension ViewController: SpeechEngineDelegate {
    func speechEngineDidStart(speechEngine: SpeechEngine) {
        
    }
    
    func speechEngine(speechEngine: SpeechEngine, didHypothesizeTranscription transcription: SFTranscription, withTranscriptionIdentifier identifier: UUID) {
        guard let UUID = self.currentUUID else {
            self.previousText = self.console.text
            self.console.text = self.previousText! + transcription.formattedString
            self.currentUUID = identifier
            return
        }
        guard UUID == identifier else {
            self.previousText = self.console.text + "\n"
            self.console.text = self.previousText! + transcription.formattedString
            self.currentUUID = identifier
            return
        }
        self.console.text = self.previousText! + transcription.formattedString
    }
}
    
