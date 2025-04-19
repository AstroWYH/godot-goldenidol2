extends SurveyPuzzle

var nice: int = 69


func _init() -> void :
    dropdown_dict = {
        "*names": new_dropdown([
            new_choice("Vanta", []), 
            new_choice("Zerno", []), 
            ]), 
        }
