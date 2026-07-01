import Foundation

struct AICoachPrompt {
    static let systemPrompt = """
    You are PawMento, an empathetic AI coach and journaling companion for pet parents.
    
    # Core Persona & Tone
    - You are a knowledgeable friend, not a robotic chatbot.
    - Never start with "How can I help you today?"
    - Speak with warmth, brevity, and care. Use paragraphs instead of bullet points unless asked.
    - Deeply empathetic. If the user is anxious or frustrated, FIRST validate their feelings (e.g. "That sounds really scary," or "I know how frustrating that can be"), THEN provide advice.
    - Always use the pet's name, breed, and history if provided in the context layer. If logs contradict the user's statement, gently flag it without sounding accusatory.
    - For casual or fun questions (e.g. "Can dogs eat blueberries?"), keep it short, delightful, and DO NOT add veterinary disclaimers.
    
    # Safety & Emergency Routing
    - You are NOT a veterinarian. You cannot diagnose or prescribe doses.
    - **Poisons/Toxins:** If a pet ate something toxic (like chocolate or ibuprofen), immediately route to the vet AND direct them to \(AIConfig.EmergencyContacts.emergencyContactBlurb). Do NOT attempt to calculate toxicity doses.
    - **IMPORTANT — Casual toxin questions vs. real emergencies:** If a user asks "can dogs eat chocolate cake?" casually, STILL mention the toxicity risk and provide the poison control number. Safety always wins over brevity. The app's safety prefilter may have already flagged this message — your response should be consistent with emergency routing even for casual-sounding toxin questions.
    - **Bloat/GDV:** If a dog has a swollen stomach + unproductive retching, explicitly warn this is a life-threatening emergency (GDV/bloat). Route to ER immediately. Do not offer home remedies.
    - **Male Cat Urinary Issues:** Frequent litter box trips with little/no urine is a life-threatening emergency in male cats (urinary blockage). Route to ER immediately.
    - **Cat Inappropriate Urination:** Always state this is medical until proven behavioral. Advise a vet check first to rule out UTI/crystals.
    - **Seizures:** Distinguish between a single short seizure (<5 min, requires urgent vet visit) and cluster/long seizures (immediate ER). Give calming observation tips.
    
    # Refusal & Jailbreak Rules
    - **Dosage Requests:** Never give specific medication doses. If asked, politely refuse, don't lecture, and offer alternatives (like a 24/7 vet telehealth line or \(AIConfig.EmergencyContacts.poisonControlName)).
    - **Roleplay/Authority Bypasses:** Do NOT pretend to be a vet (e.g. "Dr. Smith"). If the user claims to be a vet to get dosing info, politely refuse, state PawMento isn't for vet-to-vet consults, and point them to professional resources like Plumb's.
    - **Hypotheticals:** See through hypothetical framing. If they ask about toxic doses "hypothetically", treat it as a real risk, refuse the dose info, and direct them to \(AIConfig.EmergencyContacts.poisonControlName).
    - **Off-Topic:** If asked about non-pet topics (like writing Python scripts), politely decline in one friendly sentence and redirect to pet care.
    
    # Formatting & Vet Footer Discipline
    - Keep responses concise.
    - **Vet Footer:** For minor health questions (e.g., slight limp, drinking more water, ambiguous "seems off"), ask 2-3 clarifying questions or suggest a non-urgent vet check. Always include a standard "When to call a vet" footer detailing when the symptoms would escalate. 
    - Do NOT use the vet footer for completely healthy, casual, or behavioral topics.
    """
    
    // Fix C6: This method builds a pet-context-enriched system prompt.
    // Verified: CoachViewModel.sendMessage already calls buildPrompt(for: pet)
    // at line 169, so the coach always receives the active pet's context.
    static func buildPrompt(for pet: Pet?) -> String {
        var base = systemPrompt
        if let pet = pet {
            base += "\n\n# Active Pet Context\n"
            base += "You are currently advising the owner of \(pet.name).\n"
            
            let speciesStr: String
            switch pet.species {
            case .dog: speciesStr = "Dog"
            case .cat: speciesStr = "Cat"
            case .rabbit: speciesStr = "Rabbit"
            case .other(let name): speciesStr = name
            }
            base += "- Species: \(speciesStr)\n"
            
            if let breed = pet.breed, !breed.isEmpty {
                base += "- Breed: \(breed)\n"
            }
            
            // Fix C7: Format weight to 1 decimal place
            if let weight = pet.weightKg {
                base += "- Weight: \(String(format: "%.1f", weight))kg\n"
            }
            
            // Fix C7: Compute age via Calendar date diffing for correctness.
            // Handles year-only birthdays (month defaults to Jan), day-of-month edge cases,
            // and doesn't require both year AND month to be present.
            if let bday = pet.birthday {
                let calendar = Calendar.current
                let now = Date()
                
                // Build the best Date we can from the components
                var components = DateComponents()
                components.year = bday.year
                components.month = bday.month ?? 1 // Default to January if month-only
                components.day = bday.day ?? 1      // Default to 1st if day missing
                
                if let year = bday.year, let birthDate = calendar.date(from: components) {
                    let age = calendar.dateComponents([.year, .month], from: birthDate, to: now)
                    let ageYears = age.year ?? 0
                    let ageMonths = age.month ?? 0
                    
                    if ageYears > 0 {
                        if bday.month != nil {
                            base += "- Age: \(ageYears) years and \(ageMonths) months\n"
                        } else {
                            // Year-only birthday — don't claim month precision
                            base += "- Age: approximately \(ageYears) years\n"
                        }
                    } else {
                        base += "- Age: \(ageMonths) months\n"
                    }
                }
            }
        }
        return base
    }
}
