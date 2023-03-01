// conv
global state_path = 'utils/data/state.json';
global faq_answer_path = 'utils/data/faq_answer.json';
global classifier_path = 'utils/data/classifer_data.json';

global main_root = '';
global dialogue_root = '';
global prev_response = "";
global entity_label =[];

global faq_score = 0.2;
global conv_score = 0.5;


// tubo

global events_path = "utils/data/events.json";
global sentiments_path = "utils/data/tubo_data/sentiments.json";
global commentary_path = "utils/data/tubo_data/commentary.json";
global prompt_path = "utils/data/tubo_data/prompt.json";

// 28, 27
global sentiment_score = 0.27;
global commentary_score = 0.27;
global event_type_score = 0.27;
global entity_response_score = 0;

global to_remove = ['yes', 'no', 'oh', "i don't know", 'nope', 'yeah', 'nah', 'maybe', 'possibly', 'perhaps', 'sorry', 'please', 'thank you', 'okay', 'alright', 'uh-huh', 'uh-uh', 'oops', 'huh', 'ugh', 'yikes', 'meh', 'mhm', 'gotcha', 'well', 'you know', 'so', 'kinda', 'sorta', 'basically', 'actually', 'literally', 'seriously', 'definitely', 'absolutely', 'totally', 'completely', 'utterly', 'quite', 'pretty', 'fairly', 'rather', 'somehow', 'somewhat', 'anyway', 'anyhow', 'anyways', 'alas', 'voila', 'ta-da', 'nah'];
global tobu_user = "Tharick";