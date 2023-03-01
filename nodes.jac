node dialogue_state{
    has imprint;
    has name;

    can tfm_ner.extract_entity;
    can use.text_classify;

    // custom modules
    can flow.info_json;
    can flow.select_response;
    can flow.gen_response;
    can flow.collect_info;
    can flow.select_options;
    can flow.check_required_entity;

    can load_json{
        if(!visitor.state_json){
            visitor.state_json = file.load_json(global.state_path);
        }
    }

    can classify_intent {
        if(visitor.respond){

            imprints = -[intent_transition]->.imprint;
            intent_labels = -[intent_transition]->.edge.intent;
            std.log("INTENT_LABELS: ", intent_labels);
            max_score = global.conv_score;
            intent = "";

            for imprint in imprints {
                if (imprint[0].type == dict ){

                    best_answer = use.text_classify(
                        text = visitor.utterance,
                        classes = imprint[0]['list_imprint'].list
                    );
                    nn = best_answer['match_idx'];
                    if (best_answer['scores'][nn] > max_score){
                        max_score = best_answer['scores'][nn];
                        intent = imprint[0].name;
                    }
                    std.out("best_answer intent");
                    std.out(best_answer);
                }
            }
            
            if (max_score > global.conv_score and intent in intent_labels){
                visitor.threshold = true;
                visitor.predicted_intent = intent;
            }
            std.log("THRESHOLD: ", global.conv_score,"   SCORE: " , max_score);
            std.log("INTENT:  ", visitor.predicted_intent);
        }
    }

    can extract_entities {
        if(visitor.respond){
            res = tfm_ner.extract_entity(visitor.utterance);
            if(res.type == list || res.type == dict){

                for ent in res {
                    ent_type = ent["entity_value"];
                    ent_text = ent["entity_text"];
                    if ( !(ent_type in visitor.extracted_entities) ){
                        visitor.extracted_entities[ent_type] = [];
                    }
                    
                    if( ent_text not in visitor.extracted_entities[ent_type] ){
                        visitor.extracted_entities[ent_type].l::append(ent_text);
                    }
                }
            }
            std.log("ENTITIES:  ", visitor.extracted_entities);
        }
    }

    can business_logic {
        if(visitor.respond or visitor.override_respond){
            visitor.dialogue_context.dict::update(visitor.extracted_entities);
            for label in visitor.extracted_entities{
                visitor.dialogue_context[label]=visitor.extracted_entities[label][0];
            }
        }
    }

    can nlu with talk entry {
        // if(visitor.respond or visitor.override_respond){}
    }

    can process with talk entry {
        if(visitor.respond){

            required_entities = -[entity_transition]->.edge.entities;
            redirect = -[redirect_transition]->;

            if(visitor.extracted_entities and !visitor.next_state and required_entities){
                // if(required_entities){
                    // std.out("Trasition:   3");
                    for entity in required_entities{
                        required = flow.check_required_entity(entity, visitor.extracted_entities.d::keys);
                        if(required == true){
                            // std.out("Trasition:   16");
                            visitor.next_state = -[entity_transition(entities == entity)]->[0];
                            visitor.override_respond = true;
                        }
                        elif(visitor.predicted_intent_fixed){
                            // std.out("Trasition:   15");
                            visitor.next_state = -[intent_transition_fixed(intent == visitor.predicted_intent_fixed)]->[0];
                            visitor.override_respond = true;
                        }
                        elif(visitor.predicted_intent){
                            // std.out("Trasition:   14");
                            visitor.next_state = -[intent_transition(intent == visitor.predicted_intent)]->[0];
                            visitor.override_respond = true;
                        }
                        elif(redirect){
                            // std.out("Trasition:   13");
                            visitor.next_state = -[redirect_transition]->[0];
                            visitor.override_respond = true;
                        }
                        else{
                            // std.out("Trasition:   12");
                            // std.out('NOTE_: Can Process else ran 2!');
                            // visitor.override_respond = false;
                        }
                    }
                // }
                // elif(visitor.predicted_intent_fixed){
                //     std.out("Trasition:   11");
                //     visitor.next_state = -[intent_transition_fixed(intent == visitor.predicted_intent_fixed)]->[0];
                //     visitor.override_respond = true;
                // }
                // elif(visitor.predicted_intent){
                //     std.out("Trasition:   10");
                //     visitor.next_state = -[intent_transition(intent == visitor.predicted_intent)]->[0];
                //     visitor.override_respond = true;
                // }
                // elif(redirect){
                //     std.out("Trasition:   9");
                //     visitor.next_state = -[redirect_transition]->[0];
                //     visitor.override_respond = true;
                // }
                // else{
                //     std.out("Trasition:   8");
                //     // visitor.override_respond = false;
                //     // std.out('NOTE_: Can Process else ran 3!');
                // }
            }
            elif(visitor.predicted_intent_fixed){
                // std.out("Trasition:   4");
                visitor.next_state = -[intent_transition_fixed(intent == visitor.predicted_intent_fixed)]->[0];
                visitor.override_respond = true;
            }
            elif(visitor.predicted_intent and visitor.threshold ){
                // std.out("Trasition:   5");
                visitor.next_state = -[intent_transition(intent == visitor.predicted_intent)]->[0];
                visitor.override_respond = true;
            }
            elif(redirect and !visitor.next_state){
                // std.out("Trasition:   6");
                visitor.next_state = -[redirect_transition]->[0];
                visitor.override_respond = true;
            }
            else{
                // std.out("Trasition:   7");
                // visitor.override_respond = false;
                
                // std.out('NOTE_: Can Process else ran 1!');
            }
        }
    }

    can nlg with talk entry {
        if (!visitor.respond) {
            report {
                "utterance": visitor.utterance,
                "name": here.name,
                "response": visitor.response
            };
        }
    }

    can cleanup with talk entry {
        // if(visitor.respond or visitor.override_respond){
        intent_labels = -[intent_transition]->.edge.intent;
        intent_labels_fixed = -[intent_transition_fixed]->.edge.intent;
        if(intent_labels.length == 0 and intent_labels_fixed.length == 0){
            visitor.prev_state = global.dialogue_root;
        }
        else{
            visitor.prev_state = here.info['jid'];
        }
        spawn *(global.main_root) walker::maintainer( 
            prev_state = visitor.prev_state,
            dialogue_context = visitor.dialogue_context,
            prev_response = visitor.prev_response,
            state_json = visitor.state_json,
            override_respond = visitor.override_respond,

            unanswered_queue = visitor.unanswered_queue,
            answered_queue = visitor.answered_queue,
            main_queue = visitor.main_queue,
            sentiments_json =visitor.sentiments_json,
            commentary_json =visitor.commentary_json,
            events_json =visitor.events_json,
            prompts_json =visitor.prompts_json,
            current_event_type = visitor.current_event_type,
            removed_entity = visitor.removed_entity
        );
        // }
    }
}

node user {
    has id;
    has prev_state = null;
    has dialogue_context ={};
    has prev_response = "";
    has state_json= [];
    has override_respond;
    

    has unanswered_queue = [];
    has main_queue = [];
    has answered_queue = {};
    has sentiments_json = {};
    has commentary_json = {};
    has events_json = {};
    has prompts_json = {};
    has current_event_type = {};
    has removed_entity = "";



    can start_conv with talk entry {
        if (here.prev_state == null) {
            here.prev_state = global.dialogue_root;
        }
        visitor.cont_state = here.prev_state;
        visitor.prev_response = here.prev_response;
        visitor.state_json = here.state_json;
        visitor.dialogue_context = here.dialogue_context;
        visitor.override_respond = here.override_respond;

        visitor.sentiments_json = here.sentiments_json;
        visitor.commentary_json = here.commentary_json;
        visitor.events_json = here.events_json;
        visitor.prompts_json = here.prompts_json;      
        visitor.unanswered_queue = here.unanswered_queue;
        visitor.answered_queue = here.answered_queue;
        visitor.current_event_type = here.current_event_type;
        visitor.main_queue = here.main_queue;
        visitor.removed_entity = here.removed_entity;

    }

    can update_with_conv with maintainer entry {
        here.prev_state = visitor.prev_state;
        here.dialogue_context = visitor.dialogue_context;
        here.prev_response = visitor.prev_response;
        here.state_json = visitor.state_json;
        here.override_respond = visitor.override_respond;

        here.main_queue = visitor.main_queue;
        here.unanswered_queue = visitor.unanswered_queue;
        here.answered_queue = visitor.answered_queue;
        here.sentiments_json = visitor.sentiments_json;
        here.commentary_json = visitor.commentary_json;
        here.events_json = visitor.events_json;
        here.prompts_json = visitor.prompts_json;        
        here.current_event_type = visitor.current_event_type;
        here.removed_entity = visitor.removed_entity;


    }

    can clear with clear_user entry{
        here.dialogue_context = visitor.dialogue_context;

        here.main_queue = visitor.main_queue;
        here.unanswered_queue = visitor.unanswered_queue;
        here.answered_queue = visitor.answered_queue;
        here.current_event_type = visitor.current_event_type;
        here.removed_entity = visitor.removed_entity;
    }

}

node dialog:dialogue_state{
    has name="dialogue_root";

    can nlu with talk entry{
        if(visitor.respond){
            ::load_json;

            if(visitor.utterance){
                ::classify_intent;
                ::extract_entities;
                ::business_logic;
            }
            elif(!visitor.utterance){
                ::business_logic;
            }

            visitor.response = "This is the dialogue root!!";
        }
    }
    
}

// tubo


node document_memory:dialogue_state{
    has name;

    can nlu with talk entry {
        if(!visitor.respond){
            ::load_json;

            if(visitor.utterance){
                ::load_json;
                ::classify_intent;
                ::extract_entities;
                ::business_logic;
            }
            elif(!visitor.utterance){
                ::business_logic;
            }

            for state in visitor.state_json{
                if (here.name == state["name"].str){
                    visitor.dialogue_context["user_name"]=global.tobu_user; // remove
                    visitor.response = flow.gen_response(state['responses'], visitor.dialogue_context, visitor.prev_response);
                }
            }
        }
    }

    can cleanup with talk entry{
        // clear user node
        if(!visitor.respond): spawn *(global.main_root) walker::clear_user;
    }
}


node capture_memories:dialogue_state{
    has prev_commentary = "";
    has prev_sentiment = "";
    has prev_prompt_response = "";
    
    
    can load_json{
        if(!visitor.prompts_json or !visitor.events_json or !visitor.sentiments_json or !visitor.commentary_json){
            visitor.prompts_json = file.load_json(global.prompt_path);
            visitor.events_json = file.load_json(global.events_path);
            visitor.sentiments_json = file.load_json(global.sentiments_path);
            visitor.commentary_json = file.load_json(global.commentary_path);
        }
    }

    can classify_entity{
        if("event" in visitor.extracted_entities){
            best_answer = use.text_classify(
                text = visitor.extracted_entities['event'][0],
                classes = visitor.events_json.dict::keys
            );
            std.out("best_answer event");
            std.out(best_answer);
            entity_name = best_answer.match;
            idx = best_answer.match_idx;
            if (best_answer['scores'][idx] > global.event_type_score){
                visitor.current_event_type = {};
                visitor.current_event_type[entity_name]= visitor.events_json[entity_name];
                std.log("Event found: "+ best_answer.match.str + " Score: "+ best_answer['scores'][idx].str);
            }
            else{
                std.log("NO EVENT OR ACTIVITY FOUND. SOCRE: "+ global.event_type_score.str);
            }
        }

        if("activity" in visitor.extracted_entities){
            best_answer = use.text_classify(
                text = visitor.extracted_entities['activity'][0],
                classes = visitor.events_json.dict::keys
            );
            std.out("best_answer activity");
            std.out(best_answer);

            entity_name = best_answer.match;
            idx = best_answer.match_idx;
            if (best_answer['scores'][idx] > global.event_type_score){
                visitor.current_event_type = {};
                visitor.current_event_type[entity_name]= visitor.events_json[entity_name];
                std.log("Activity found: "+ best_answer.match.str + " Score: "+ best_answer['scores'][idx].str);
            }
            else{
                std.log("NO EVENT OR ACTIVITY FOUND. SOCRE: "+ global.event_type_score.str);
            }
        }

        std.out("visitor.events_json  lllllllllllllll");
        std.out(visitor.events_json);
        

        if(!visitor.current_event_type){
            visitor.main_queue = visitor.default_queue;
        }
        
    }

    can no_utterance{
        // event type, commentary
        if("event" in visitor.extracted_entities){
            ext_entity_name = visitor.extracted_entities.event[0];
            best_commentary = use.text_classify(
                text = ext_entity_name,
                classes = visitor.commentary_json.dict::keys
            );
            std.out("best_commentary");
            std.out(best_commentary);
            commentary_name = best_commentary.match;
            idx = best_commentary.match_idx;
            if (best_commentary['scores'][idx] > global.commentary_score){
                visitor.commentary = flow.gen_response(visitor.commentary_json[commentary_name].list, {}, prev_commentary);
                // visitor.current_event_type[commentary_name]= visitor.events_json[commentary_name];
                prev_commentary = visitor.commentary;
            }
            else{
                std.log("NO EVENT COMMENTARY FOUND. SOCRE: "+ global.commentary_score.str);
            }

            ev_best_commentary = use.text_classify(
                text = ext_entity_name,
                classes = visitor.events_json.dict::keys
            );
            std.out("ev_best_commentary");
            std.out(ev_best_commentary);

            
            ev_commentary_name = ev_best_commentary.match;
            idx = best_commentary.match_idx;
            if (best_commentary['scores'][idx] > global.event_type_score){
                visitor.current_event_type[ev_commentary_name]= visitor.events_json[ev_commentary_name];
            }
            else{
                std.log("NO EVENT TYPE COMMENTARY FOUND. SOCRE: "+ global.event_type_score.str);
            }
        }

        if("activity" in visitor.extracted_entities){
            ext_entity_name = visitor.extracted_entities["activity"][0];
            best_commentary = use.text_classify(
                text = ext_entity_name,
                classes = visitor.commentary_json.dict::keys
            );
            std.out("best_commentary");
            std.out(best_commentary);

            commentary_name = best_commentary.match;
            idx = best_commentary.match_idx;
            if (best_commentary['scores'][idx] > global.commentary_score){
                visitor.commentary = flow.gen_response(visitor.commentary_json[commentary_name].list, {}, prev_commentary);
                // visitor.current_event_type[commentary_name]= visitor.events_json[commentary_name];
                prev_commentary = visitor.commentary;
            }
            else{
                std.log("NO ACTIVITY COMMENTARY FOUND. SOCRE: "+ global.commentary_score.str);
            }

            ev_best_commentary = use.text_classify(
                text = ext_entity_name,
                classes = visitor.events_json.dict::keys
            );
            std.out("ev_best_commentary");
            std.out(ev_best_commentary);

            ev_commentary_name = ev_best_commentary.match;
            idx = best_commentary.match_idx;
            if (best_commentary['scores'][idx] > global.event_type_score){
                visitor.current_event_type[ev_commentary_name]= visitor.events_json[ev_commentary_name];
            }
            else{
                std.log("NO EVENT TYPE COMMENTARY FOUND. SOCRE: "+ global.event_type_score.str);
            }
        }

        std.out("visitor.events_json  lllllllllllllll  1");
        std.out(visitor.events_json);
        // sentiment
        if("sentiment" in visitor.extracted_entities){
            ext_sentiment_name = visitor.extracted_entities["sentiment"][0];
            best_sentiment = use.text_classify(
                text = ext_sentiment_name,
                classes = visitor.sentiments_json.dict::keys
            );
            std.out("sentiment");
            std.out(sentiment);

            sentiment_name = best_sentiment.match;
            idx = best_sentiment.match_idx;
            if (best_sentiment['scores'][idx] > global.sentiment_score){
                visitor.sentiment = flow.gen_response(visitor.sentiments_json[sentiment_name].list, {}, prev_sentiment);
                prev_sentiment = visitor.sentiment;
            }
            else{
                std.log("NO SENTIMENT FOUND. SOCRE: "+ global.sentiment_score.str);
            }
            
            
        }

        if(!visitor.current_event_type){
            visitor.main_queue = visitor.default_queue;
        }
        std.out("visitor.events_json  lllllllllllllll  1.2");
        std.out(visitor.events_json);
    }

    can add_events_and_activities{

        if("event" in visitor.extracted_entities or "activity" in visitor.extracted_entities and visitor.current_event_type){
            event_list= [];

            for item in visitor.main_queue{
                if(item.type == dict){
                    event_list.list::append(item.dict::keys[0]);
                }
            }
            
            for event_type in visitor.current_event_type{
                if(event_type not in event_list){
                    data = {};
                    data[event_type]= visitor.current_event_type[event_type];
                    visitor.main_queue.list::append(data);
                    visitor.answered_queue[event_type]={};
                    for item in visitor.current_event_type[event_type]{
                        if(item in visitor.main_queue){
                            visitor.main_queue.list::remove(item);
                        }
                    }
                }
            }

        }
    }

    // this is the code i used. 

    // events_json = file.load_json(global.events_path);

    // current_event_type[name]=events_json[name];

    // data[event_type]= current_event_type[event_type];
    // main_queue.list::append(data);

    // for item_m in main_queue{
    // item_m[name_m].list::remove(removed_entity);

    // how the data was passed to main_queue
    // events_json > current_event_type > main_queue

    // when i remove item from main_queue. It is also removed from events_json
    // is there another was to pass it without the item from events_json being removed.



    can update_answered_queue{
        std.out("visitor.events_json  lllllllllllllll  1.3");
        std.out(visitor.events_json);

        for item_m in visitor.main_queue{
            if(item_m.type == dict){
                main_event_name = item_m.dict::keys[0];

                if(visitor.removed_entity in item_m[main_event_name] and visitor.removed_entity not in visitor.dialogue_context){
                    std.out("visitor.events_json before \n");
                    std.out(visitor.events_json);
                    item_m[main_event_name].list::remove(visitor.removed_entity);
                    if(visitor.removed_entity not in visitor.unanswered_queue): visitor.unanswered_queue.list::append(visitor.removed_entity);
                    std.out("visitor.events_json after \n");
                    std.out(visitor.events_json);

                }

                if(item_m[main_event_name]){
                    for ent in item_m[main_event_name]{
                        if(ent in visitor.answered_queue){
                            visitor.answered_queue[main_event_name][ent]=visitor.answered_queue[ent];
                            visitor.answered_queue.dict::pop(ent);
                        }
                        elif(ent in visitor.dialogue_context){
                            visitor.answered_queue[main_event_name][ent]=visitor.dialogue_context[ent];
                        }
                    }
                }

                for ent in visitor.answered_queue[main_event_name]{
                    if(ent in item_m[main_event_name]){
                        item_m[main_event_name].list::remove(ent);
                    }
                }

            }
            elif(item.type == str){
                if(visitor.removed_entity in visitor.main_queue and visitor.removed_entity not in visitor.dialogue_context){
                    visitor.main_queue.list::remove(visitor.removed_entity);
                    if(visitor.removed_entity not in visitor.unanswered_queue): visitor.unanswered_queue.list::append(visitor.removed_entity);
                }
                for entity in visitor.dialogue_context{
                    if(entity in visitor.main_queue){
                        visitor.answered_queue[entity]=visitor.dialogue_context[entity];
                        if(entity in visitor.main_queue): visitor.main_queue.list::remove(entity);
                    }
                }
            }
        }
        std.out("visitor.events_json  lllllllllllllll  1.3.1");
        std.out(visitor.events_json);


        if (!visitor.extracted_entities){
            for items in visitor.main_queue{
                if(items.type == dict){
                    main_name=items.dict::keys[0];
                    if(visitor.removed_entity in items.dict::values[0]){
                        items[main_name].list::remove(visitor.removed_entity);
                    }
                }
                elif(items.type == str){
                    if(visitor.removed_entity in visitor.main_queue){
                        visitor.main_queue.list::remove(visitor.removed_entity);
                    }
                }
            }
        }
        std.out("visitor.events_json  lllllllllllllll  1.4");
        std.out(visitor.events_json);

        for event in visitor.answered_queue{
            if(event in visitor.events_json.dict::keys){
                for item in visitor.dialogue_context{
                    if(item in visitor.events_json[event]){
                        visitor.answered_queue[event][item]=visitor.dialogue_context[item];
                    }
                }
            }
            elif(event in visitor.events_json.dict::keys){
                for item in visitor.dialogue_context{
                    if(item in visitor.events_json[event]){
                        visitor.answered_queue[event][item]=visitor.dialogue_context[item];
                    }
                }
            }
        }
        std.out("visitor.events_json  lllllllllllllll  2");
        std.out(visitor.events_json);
    }

    can create_commentary_and_sentimemt{
        best_commentary = use.text_classify(
            text = visitor.utterance,
            classes = visitor.commentary_json.dict::keys
        );
        std.out("best_commentary");
        std.out(best_commentary);
        commentary_name = best_commentary.match;
        idx = best_commentary.match_idx;
        if (best_commentary['scores'][idx] > global.commentary_score){
            visitor.commentary = flow.gen_response(visitor.commentary_json[commentary_name].list, {}, prev_commentary);
            prev_commentary = visitor.commentary;
        }
        else{
            std.log("NO COMMENTARY FOUND. SOCRE: "+ global.commentary_score.str);
        }

        best_sentiment = use.text_classify(
            text = visitor.utterance,
            classes = visitor.sentiments_json.dict::keys
        );
        std.out("best_sentiment");
        std.out(best_sentiment);

        sentiment_name = best_sentiment.match;
        idx = best_sentiment.match_idx;
        if (best_sentiment['scores'][idx] > global.sentiment_score){
            visitor.sentiment = flow.gen_response(visitor.sentiments_json[sentiment_name].list, {}, prev_sentiment);
            prev_sentiment = visitor.sentiment;
        }
        else{
            std.log("NO SENTIMENT FOUND. SOCRE: "+ global.sentiment_score.str);
        }


    }

    can nlu with talk entry{
        if(visitor.respond or visitor.override_respond){
            visitor.override_respond = false;

            if(visitor.utterance){
                ::classify_intent;
                ::extract_entities;
                ::business_logic;
                ::load_json;

                ::classify_entity;
                ::add_events_and_activities;
                ::update_answered_queue;
                ::create_commentary_and_sentimemt;
            }
            elif(!visitor.utterance){
                ::business_logic;
                ::load_json;
                ::no_utterance;
                ::add_events_and_activities;
                ::update_answered_queue;
            }
            

            ans_list = [];
            response_list = {};
            create_response = "";

            ii = 0;
            max_score = 0.01;
            select_response_list = [];


            // update extracted_sentences
            if(visitor.utterance){
                if(!visitor.predicted_intent and visitor.utterance.list.length > 3){
                    if("extracted_sentences" not in visitor.dialogue_context){
                        visitor.dialogue_context["extracted_sentences"]=[visitor.utterance];
                    }
                    elif(visitor.utterance not in visitor.dialogue_context["extracted_sentences"]){
                        visitor.dialogue_context["extracted_sentences"].list::append(visitor.utterance);
                    }
                }
            }


            // get all the entity in answered_queue
            for ans_ent in visitor.answered_queue{
                if(visitor.answered_queue[ans_ent].type == dict){
                    for ent in visitor.answered_queue[ans_ent]{
                        if(ent not in ans_list): ans_list.list::append(ent);
                    }
                }
                elif(visitor.answered_queue[ans_ent].type == str){
                    if(ans_ent not in ans_list): ans_list.list::append(ans_ent);
                }
            }


            // create response list from all the entity in ans_list if none. add default response 
            for item in visitor.main_queue{
                if(item.type == dict){
                    for ent in item.dict::values[0]{
                        if(ent in visitor.prompts_json["response"]){
                            number_of_selected_prompt = 0;
                            for ans_entity in visitor.prompts_json["response"][ent].dict::keys{
                                if(ans_entity in ans_list){
                                    response_list[ent]=visitor.prompts_json["response"][ent][ans_entity];
                                    number_of_selected_prompt +=1;
                                }
                            }
                            if(number_of_selected_prompt == 0){
                                response_list[ent]=visitor.prompts_json["response"][ent]["default"];
                            }
                        }
                    }
                }
                elif(item.type == str){
                    if(item in visitor.prompts_json["response"]){
                        number_of_selected_prompt = 0;
                        for ans_entity in visitor.prompts_json["response"][item].dict::keys{
                            if(ans_entity in ans_list){
                                response_list[ent]=visitor.prompts_json["response"][item][ans_entity];
                                number_of_selected_prompt +=1;
                            }
                        }
                        if(number_of_selected_prompt == 0){
                            response_list[item]=visitor.prompts_json["response"][item]["default"];
                        }
                    }
                }
            }


            // select entity and their response 
            if(response_list and !visitor.utterance){
                rand_ent = rand.choice(response_list.dict::keys);
                select_response_list = response_list[rand_ent];
                visitor.removed_entity = rand_ent;
            }
            elif(response_list and visitor.utterance){
                while (max_score < 0.1){
                    best_answer = {};
                    for response in response_list{
                        best_answer = use.text_classify(
                            text = visitor.dialogue_context["extracted_sentences"][ii],
                            classes = response_list[response]
                        );
                    }
                    nn = best_answer['match_idx'];

                    if (best_answer['scores'][nn] > max_score){
                        max_score = best_answer['scores'][nn];
                        visitor.removed_entity = response;
                        select_response_list = response_list[response];
                    }

                    leng = visitor.dialogue_context["extracted_sentences"].length - 1;
                    if (max_score < 0.1){
                        ii +=1;
                        if(ii >= leng){
                            break;
                        }
                    }
                }
            }


            // select a random response and update placeholders
            if(select_response_list){
                if (visitor.answered_queue){
                    select_context = {};
                    for items in visitor.answered_queue{
                        if (visitor.answered_queue[items].type == dict){
                            for item in visitor.answered_queue[items]{
                                select_context[item]=visitor.answered_queue[items][item];
                            }
                        }
                        elif(visitor.answered_queue[items].type == str){
                            select_context[items]=visitor.answered_queue[items];
                        }
                    }
                    create_response = flow.gen_response(select_response_list.list, select_context, prev_prompt_response);
                    prev_prompt_response = create_response;
                }
            }


            // combine commentary, sentiment and prompt to create response
            if (visitor.sentiment != "" or visitor.commentary !="" and create_response){
                visitor.response = visitor.sentiment.str + " " + visitor.commentary.str + " " + create_response.str;
            }
            elif(create_response){
                visitor.response = create_response.str;
            }

            
            // set next transition state
            if (visitor.response) {
                visitor.next_state = here;

                std.out("__________________________________________________");
            
                std.out("\n main_queue");
                std.out(visitor.main_queue);
                std.out("\n answered_queue");
                std.out(visitor.answered_queue);
                std.out("\n unanswered_queue");
                std.out(visitor.unanswered_queue);

                std.out("\n__________________________________________________");
            }
            elif!(visitor.response){
                // std.out("__________________________________________________");
            
                // std.out("\n main_queue");
                // std.out(visitor.main_queue);
                // std.out("\n answered_queue");
                // std.out(visitor.answered_queue);
                // std.out("\n unanswered_queue");
                // std.out(visitor.unanswered_queue);

                // std.out("\n__________________________________________________");

                main_list = [];
                for item in visitor.main_queue{
                    if(item.type == dict){
                        for ent in item.dict::values[0]{
                            main_list.list::append(ent);
                        }
                    }
                    elif(item.type == str){
                        main_list.list::append(item);
                    }
                }

                if(!main_list and visitor.unanswered_queue): visitor.predicted_intent_fixed = "unanswered_queue";
                visitor.respond = true;
                visitor.next_state = null;
            }
        }
    }

}


node unanswered_queue:dialogue_state{
    
    can load_json{
        if(!visitor.prompts_json or !visitor.events_json or !visitor.sentiments_json or !visitor.commentary_json or !visitor.state_json){
            visitor.prompts_json = file.load_json(global.prompt_path);
            visitor.events_json = file.load_json(global.events_path);
            visitor.sentiments_json = file.load_json(global.sentiments_path);
            visitor.commentary_json = file.load_json(global.commentary_path);
            visitor.state_json = file.load_json(global.state_path);
        }
    }
    
    can update_answered_queue{
        std.out("update_answered_queue");
        std.out(visitor.dialogue_context);
        std.out(visitor.events_json);
        for event in visitor.answered_queue{
            std.out(event);
            std.out(visitor.events_json.dict::keys);
            if(event in visitor.events_json.dict::keys){
                std.out("yes");
                std.out(visitor.events_json[event]);
                for item in visitor.dialogue_context{
                    std.out("item");
                    if(item in visitor.events_json[event]){
                        std.out(item);
                        visitor.answered_queue[event][item]=visitor.dialogue_context[item];
                    }
                }
            }
            // elif(event in visitor.events_json.dict::keys){
            //     for item in visitor.dialogue_context{
            //         if(item in visitor.events_json[event]){
            //             visitor.answered_queue[event][item]=visitor.dialogue_context[item];
            //         }
            //     }
            // }
        }
    }

    can update_unanswered_queue{
        to_remove_from_unans = [];
        for item in visitor.unanswered_queue{
            if(item in visitor.dialogue_context){
                to_remove_from_unans.list::append(item);
            }
        }

        for item in to_remove_from_unans{
            if(item in visitor.unanswered_queue): visitor.unanswered_queue.list::remove(item);
        }


        new_ans_list = [];
        for item in visitor.answered_queue{
            if(visitor.answered_queue[item].type == dict){
                for ent in visitor.answered_queue[item].dict::keys{
                    new_ans_list.list::append(ent);
                }
            }
            elif(visitor.answered_queue[item].type == str){
                new_ans_list.list::append(item);
            }
        }
        // std.out(visitor.respond);
        // std.out(visitor.override_respond);
        // std.out("visitor.removed_entity");
        // std.out(visitor.removed_entity);
        // std.out("visitor.unanswered_queue 1");
        // std.out(visitor.unanswered_queue);

        

        if(visitor.respond and visitor.removed_entity in visitor.unanswered_queue): visitor.unanswered_queue.list::remove(visitor.removed_entity);
        // elif(visitor.extracted_entities and visitor.removed_entity not in visitor.extracted_entities and visitor.removed_entity in visitor.unanswered_queue): visitor.unanswered_queue.list::remove(visitor.removed_entity);
        // elif(visitor.removed_entity not in new_ans_list){
        //     visitor.unanswered_queue.list::append(visitor.removed_entity);
        //     visitor.removed_entity = "";
        //     std.out("this ran");
        // }
        // std.out("visitor.unanswered_queue 2");
        // std.out(visitor.unanswered_queue);


    }

    can classify_entity{
        if("event" in visitor.extracted_entities){
            best_answer = use.text_classify(
                text = visitor.extracted_entities['event'][0],
                classes = visitor.events_json.dict::keys
            );
            std.out("best_answer");
            std.out(best_answer);

            entity_name = best_answer.match;
            idx = best_answer.match_idx;
            if (best_answer['scores'][idx] > global.event_type_score){
                visitor.current_event_type = {};
                visitor.current_event_type[entity_name]= visitor.events_json[entity_name];
                std.log("Event found: "+ best_answer.match.str + " Score: "+ best_answer['scores'][idx].str);
            }
            else{
                std.log("NO EVENT OR ACTIVITY FOUND. SOCRE: "+ global.event_type_score.str);
            }
        }

        if("activity" in visitor.extracted_entities){
            best_answer = use.text_classify(
                text = visitor.extracted_entities['activity'][0],
                classes = visitor.events_json.dict::keys
            );
            std.out("best_answer");
            std.out(best_answer);

            entity_name = best_answer.match;
            idx = best_answer.match_idx;
            if (best_answer['scores'][idx] > global.event_type_score){
                visitor.current_event_type = {};
                visitor.current_event_type[entity_name]= visitor.events_json[entity_name];
                std.log("Activity found: "+ best_answer.match.str + " Score: "+ best_answer['scores'][idx].str);
            }
            else{
                std.log("NO EVENT OR ACTIVITY FOUND. SOCRE: "+ global.event_type_score.str);
            }
        }    
        std.out("visitor.events_json  lllllllllllllll  3");
        std.out(visitor.events_json);    
    }

    can no_utterance{
        // event type, commentary
        if("event" in visitor.extracted_entities){
            ev_best_commentary = use.text_classify(
                text = ext_entity_name,
                classes = visitor.events_json.dict::keys
            );
            std.out("ev_best_commentary");
            std.out(ev_best_commentary);

            ev_commentary_name = ev_best_commentary.match;
            idx = best_commentary.match_idx;
            if (best_commentary['scores'][idx] > global.event_type_score){
                visitor.current_event_type[ev_commentary_name]= visitor.events_json[ev_commentary_name];
            }
            else{
                std.log("NO EVENT TYPE COMMENTARY FOUND. SOCRE: "+ global.event_type_score.str);
            }
        }

        if("activity" in visitor.extracted_entities){
            ev_best_commentary = use.text_classify(
                text = ext_entity_name,
                classes = visitor.events_json.dict::keys
            );
            std.out("ev_best_commentary");
            std.out(ev_best_commentary);
            ev_commentary_name = ev_best_commentary.match;
            idx = best_commentary.match_idx;
            if (best_commentary['scores'][idx] > global.event_type_score){
                visitor.current_event_type[ev_commentary_name]= visitor.events_json[ev_commentary_name];
            }
            else{
                std.log("NO EVENT TYPE COMMENTARY FOUND. SOCRE: "+ global.event_type_score.str);
            }
        }

        std.out("visitor.events_json  lllllllllllllll    4");
        std.out(visitor.events_json);
    }

    can add_events_and_activities{

        if("event" in visitor.extracted_entities or "activity" in visitor.extracted_entities and visitor.current_event_type){
            event_list= [];

            for item in visitor.main_queue{
                if(item.type == dict){
                    event_list.list::append(item.dict::keys[0]);
                }
            }
            
            for event_type in visitor.current_event_type{
                if(event_type not in event_list){
                    data = {};
                    data[event_type]= visitor.current_event_type[event_type];
                    visitor.main_queue.list::append(data);
                    visitor.answered_queue[event_type]={};
                    for item in visitor.current_event_type[event_type]{
                        if(item in visitor.main_queue){
                            visitor.main_queue.list::remove(item);
                        }
                    }
                }
            }

        }
    }

    can nlu with talk entry{
        if(visitor.respond or visitor.override_respond){
            visitor.override_respond = false;

            if(visitor.utterance){
                // std.out("insidee");
                ::load_json;
                ::classify_intent;
                ::extract_entities;
                ::classify_entity;
                ::add_events_and_activities;
                ::business_logic;
                ::update_answered_queue;
                ::update_unanswered_queue;
                
            }
            elif(!visitor.utterance){
                ::load_json;
                ::business_logic;
                ::no_utterance;
                ::add_events_and_activities;
                ::update_answered_queue;
                ::update_unanswered_queue;
            }

            std.out("__________________________________________________");
            
            std.out("\n main_queue");
            std.out(visitor.main_queue);
            std.out("\n answered_queue");
            std.out(visitor.answered_queue);
            std.out("\n unanswered_queue");
            std.out(visitor.unanswered_queue);

            std.out("\n__________________________________________________");

            ans_list = [];
            response_list = {};
            ii = 0;
            max_score = 0.01;
            select_response_list = [];
            select_context = {};
            chosen_response= "";
            state_response = "";



            // update extracted_sentences
            if(visitor.utterance){
                if(!visitor.predicted_intent and visitor.utterance.list.length > 3){
                    if("extracted_sentences" not in visitor.dialogue_context){
                        visitor.dialogue_context["extracted_sentences"]=[visitor.utterance];
                    }
                    elif(visitor.utterance not in visitor.dialogue_context["extracted_sentences"]){
                        visitor.dialogue_context["extracted_sentences"].list::append(visitor.utterance);
                    }
                }
            }


            // get all the entity in answered_queue
            for ans_ent in visitor.answered_queue{
                if(visitor.answered_queue[ans_ent].type == dict){
                    for ent in visitor.answered_queue[ans_ent]{
                        if(ent not in ans_list): ans_list.list::append(ent);
                    }
                }
                elif(visitor.answered_queue[ans_ent].type == str){
                    if(ans_ent not in ans_list): ans_list.list::append(ans_ent);
                }
            }


            // create response list from all the entity in ans_list if none. add default response 
            for item in visitor.unanswered_queue{
                if(item in visitor.prompts_json["response"]){
                    // std.out(item);
                    for ent in visitor.prompts_json["response"][item].dict::keys{
                        // std.out(ent);
                        number_of_selected_prompt = 0;
                        if(ent in ans_list){
                            response_list[item]=visitor.prompts_json["response"][item][ent];
                            number_of_selected_prompt += 1;
                        }
                        elif(number_of_selected_prompt == 0){
                            response_list[item]=visitor.prompts_json["response"][item]['default'];
                        }
                    }
                }
            }

            std.out("response_list");
            std.out(response_list);


            // select entity and their response 
            if(response_list and !visitor.utterance){
                rand_ent = rand.choice(response_list.dict::keys);
                select_response_list = response_list[rand_ent];
                visitor.removed_entity = rand_ent;
            }
            elif(response_list and visitor.utterance){
                while (max_score < 0.1){
                    best_answer = {};
                    for response in response_list{
                        best_answer = use.text_classify(
                            text = visitor.dialogue_context["extracted_sentences"][ii],
                            classes = response_list[response]
                        );
                    }
                    std.out(best_answer);
                    nn = best_answer['match_idx'];

                    if (best_answer['scores'][nn] > max_score){
                        max_score = best_answer['scores'][nn];
                        visitor.removed_entity = response;
                        select_response_list = response_list[response];
                    }

                    leng = visitor.dialogue_context["extracted_sentences"].length - 1;
                    if (max_score < 0.1){
                        ii +=1;
                        if(ii >= leng){
                            break;
                        }
                    }
                }
            }
            std.out("select_response_list");
            std.out(select_response_list);


            // create a dict with all the entities in answered_queue
            for items in visitor.answered_queue{
                if (visitor.answered_queue[items].type == dict){
                    for item in visitor.answered_queue[items]{
                        select_context[item]=visitor.answered_queue[items][item];
                    }
                }
                elif(visitor.answered_queue[items].type == str){
                    select_context[items]=visitor.answered_queue[items];
                }
            }


            // select a random prompt and update the placeholders
            if(select_response_list and select_context){
                chosen_response = flow.gen_response(select_response_list.list, select_context, visitor.prev_response);
            }
            

            // select a random state response and update the placeholders
            for state in visitor.state_json{
                if (here.name == state["name"].str){
                    arry = flow.select_response({}, state['responses'], {}, visitor.prev_response);
                    state_response = arry['response'];
                }
            }


            // combine the state and prompt to create response 
            if (chosen_response and state_response){
                visitor.response = state_response.str + " " + chosen_response.str;
            }


            // check if main_queue is empty
            main_list = [];
            for item in visitor.main_queue{
                if(item.type == dict){
                    for ent in item.dict::values[0]{
                        main_list.list::append(ent);
                    }
                }
                elif(item.type == str){
                    main_list.list::append(item);
                }
            }


            // set next transition state
            if(main_list){
                // std.out("process 1");
                visitor.respond = true;
            }
            elif(visitor.unanswered_queue){
                // std.out("process 2");
                visitor.next_state = here;
            }
            elif(!visitor.unanswered_queue){
                // std.out("process 3");
                visitor.predicted_intent_fixed = "additional_memory";
                visitor.respond = true;
            }
            // else: std.out("process 4");
        }
    }
}


node additional_memory:dialogue_state{

    can load_json{
        if(!visitor.state_json){
            visitor.state_json = file.load_json(global.state_path);
        }
    }

    can nlu with talk entry {
        if(!visitor.respond){
            if(visitor.utterance){
                ::load_json;
                ::classify_intent;
                ::extract_entities;
                ::business_logic;
            }
            elif(!visitor.utterance){
                ::load_json;
                ::business_logic;
            }

            for state in visitor.state_json{
                if (here.name == state["name"].str){
                    arry = flow.select_response({}, state['responses'], {}, visitor.prev_response);
                    visitor.response = arry['response'];
                }
            }
        }
    }
}


node summary_template:dialogue_state{
    can local.shorten_str;
    can local.add_full_stop;

    can summarize{ 
        sss = local.add_full_stop(visitor.dialogue_context["extracted_sentences"], global.to_remove);
        sentence1 = ''.str::join(sss);

        subject_title_1 = local.shorten_str(text= sentence1, max_length=40);
        subject_title = subject_title_1 + "...";

        visitor.dialogue_context["summary"] = sentence1;

        if(visitor.image_urls): spawn *(global.main_root) walker::create_memory(memory_context=visitor.dialogue_context, image_urls=visitor.image_urls, subject_title = subject_title, gs_description=sentence1, local_sentiments=visitor.sentiments_json);
        else: spawn *(global.main_root) walker::create_memory(memory_context=visitor.dialogue_context, subject_title = subject_title, gs_description=sentence1, local_sentiments=visitor.sentiments_json);
    }

    can nlu with talk entry {
        // std.out("visitor.respond summaryyyyyyyyyyyyyyyyyyyyyyyyyyyyy");
        // std.out(visitor.respond);
        // std.out(visitor.override_respond);
        if (!visitor.respond or visitor.override_respond){
            visitor.override_respond = false;
            ::classify_intent;
            ::extract_entities;
            ::business_logic;

            ::summarize;
            
            for state in visitor.state_json{
                if (here.name == state["name"].str){
                    arry = flow.select_response({}, state['responses'], {}, visitor.prev_response);
                    visitor.response = arry['response'] + ' "' + visitor.dialogue_context["summary"] + '".';
                }
            }
        }                
    }
}
