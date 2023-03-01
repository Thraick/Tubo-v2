actions load module jac_nlp.tfm_ner
actions load module jac_nlp.use_enc

actions load local utils/model/local/local_module.py
actions load local utils/model/local/flow.py
actions load local utils/model/local/tobu.py
actions load module jac_nlp.sbert_sim


graph delete active:graph
jac build main.jac
graph create -set_active true
sentinel register -set_active true -mode ir main.jir

walker run init


walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"happy\"], \"event\": [\"birthday\"], \"emotion\": [\"amazing\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"Lighthearted\"], \"date\": [\"yesterday\"], \"event\": [\"birthday\"], \"emotion\": [\"amazing\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"glad\"], \"age\": [\"22 years old\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"pleased\"], \"location\": [\"Georgetown\"]}}"
// 1

walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"happy\"], \"event\": [\"birthday\"], \"emotion\": [\"amazing\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"Cheerful\"], \"subject\": [\"anna\"], \"event\": [\"birthday\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"pleased\"], \"location\": [\"Georgetown\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"Lighthearted\"], \"date\": [\"yesterday\"], \"event\": [\"birthday\"], \"emotion\": [\"amazing\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"glad\"], \"people\": [\"friends\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"glad\"], \"age\": [\"22 years old\"]}}"
walker run talk -ctx "{\"utterance\": \"I gave her a gift.\"}"
walker run talk -ctx "{\"utterance\": \"and a hug too.\"}"

walker run talk -ctx "{\"utterance\": \"no\"}"


// 2

walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"happy\"], \"date\": [\"last monday\"], \"subject\": [\"anna\"], \"event\": [\"anniversary\"], \"emotion\": [\"amazing\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"emotion\": [\"amazing\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"location\": [\"home\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"people\": [\"family\"]}}"
walker run talk -ctx "{\"utterance\": \"i had so much fun with my family\"}"
walker run talk -ctx "{\"utterance\": \"and my old friends.\"}"

walker run talk -ctx "{\"utterance\": \"nah nah it's all good\"}"


// 3
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"happy\"], \"date\": [\"wednesday\"], \"event\": [\"concert\"]}}"
walker run talk -ctx "{\"extracted_entities\": {}}"
walker run talk -ctx "{\"extracted_entities\": {\"location\": [\"Georgetown\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"lonely\"], \"people\": [\"alone\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"lonely\"], \"emotion\": [\"amazing\"]}}"

walker run talk -ctx "{\"utterance\": \"I saw an alien at the concert.\"}"
walker run talk -ctx "{\"utterance\": \"it was a green alien\"}"
walker run talk -ctx "{\"utterance\": \"not really\"}"

// 4
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"excited\"], \"date\": [\"wednesday\"], \"activity\": [\"running\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"location\": [\"in the woods\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"scary\"], \"people\": [\"alone\"], \"emotion\": [\"scared\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"weather\": [\"raining\"]}}"
walker run talk -ctx "{\"utterance\": \"no that's all\"}"


// 5
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"excited\"], \"date\": [\"wednesday\"], \"activity\": [\"hunting\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"disappointed\"], \"emotion\": [\"scared\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"weather\": [\"sunny\"], \"sentiment\": [\"good\"], \"activity\": [\"hunting\"]}}"
walker run talk -ctx "{\"extracted_entities\": {}}"
walker run talk -ctx "{\"extracted_entities\": {\"people\": [\"friends\"]}}"
walker run talk -ctx "{\"utterance\": \"I didn't caught anything\"}"
walker run talk -ctx "{\"utterance\": \"you can save it\"}"


// 6
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"shocked\"], \"people\": [\"tim\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"sweet\"], \"date\": [\"wednesday\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"wow\"], \"location\": [\"guyana\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"nice\"], \"emotion\": [\"nice\"]}}"
walker run talk -ctx "{\"utterance\": \"this is just the main queue\"}"
walker run talk -ctx "{\"utterance\": \"you can save it\"}"


// 7
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"shocked\"], \"people\": [\"tim\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"sweet\"], \"date\": [\"wednesday\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"wow\"], \"location\": [\"guyana\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"nice\"], \"emotion\": [\"nice\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"sentiment\": [\"tired\"], \"activity\": [\"swimming\"]}}"
walker run talk -ctx "{\"extracted_entities\": {\"weather\": [\"raining\"]}}"

walker run talk -ctx "{\"utterance\": \"this is just the main queue\"}"
walker run talk -ctx "{\"utterance\": \"you can save it\"}"


// done


walker run talk -ctx "{\"utterance\": \"I went walking in the park in france.\"}"
walker run talk -ctx "{\"utterance\": \"yesterday was Anna's birthday.\"}"
walker run talk -ctx "{\"utterance\": \"yesterday was Anna's birthday. it was amazing\"}"
walker run talk -ctx "{\"utterance\": \"we went to a trip in france.\"}"
walker run talk -ctx "{\"utterance\": \"yesterday was Anna's birthday. we went on a vacation\"}"
walker run talk -ctx "{\"utterance\": \"This was taken at home in Ann Arbor\"}"
walker run talk -ctx "{\"utterance\": \"it was amazing\"}"
walker run talk -ctx "{\"utterance\": \"Anna is 22 years old\"}"
walker run talk -ctx "{\"utterance\": \"it was just my friends\"}"
walker run talk -ctx "{\"utterance\": \"it was mostly sunny there\"}"

