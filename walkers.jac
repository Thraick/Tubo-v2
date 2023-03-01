walker talk {
    has utterance, phone_number;
    has predicted_intent;
    has predicted_intent_fixed;
    has extracted_entities = {};
    has dialogue_context = {};

    has response;
    has next_state;
    has prev_state;
    has cont_state;
    has respond = true;
    has threshold = false;
    has prev_response;
    has state_json = [];
    has override_respond = false;

    // tubo //
    has image_urls = null;
    has sentiment = "";
    has commentary = "";

    has default_queue=["location","people","date","emotion"]; 
    has main_queue=[];
    has answered_queue={};
    has unanswered_queue = [];
    has removed_entity = "";

    has prompts_json = {};
    has events_json = {};
    has sentiments_json = {};
    has commentary_json = {};
    has current_event_type = {};


    root {
        take -[user]-> node::user;
    }
    user {
        if(cont_state == ""): std.out('WALKER TALKER ERROR: cont_state is an EMPTY STR');
        take *(cont_state);
    }
    dialogue_state {
        if (respond) {
            take next_state else {
                report {
                    "name": here.name,
                    "response": "Sorry I can't handle that just yet."
                };
            }
            respond = false;
            if(response): prev_response = response;
        } 
    }
}

walker maintainer {
    has prev_state;
    has dialogue_context;
    has prev_response;
    has state_json;
    has override_respond;

    has unanswered_queue;
    has answered_queue;
    has prompts_json;
    has events_json;
    has sentiments_json;
    has commentary_json;
    has current_event_type;
    has removed_entity;


    root: take -[user]-> node::user;
}

walker clear_user {
    has dialogue_context ={};
    // tubo
    has unanswered_queue = [];
    has main_queue = [];
    has answered_queue = {};
    has current_event_type = {};
    has removed_entity = "";

    root: take -[user]-> node::user;
}

// tubo


walker get_memories{
    has memory={};
    has memory_list = [];

    root: take -[memories]-> node::memories else{
        report:custom = "no memories found";
    }
    memories: take -[memory]-> node::memory;
    memory{
        
        payload={};
        payload["category"]="";
        payload["date_created"]=here.date_created;
        payload["date_modified"]=here.date_modified;
        payload["description"]=here.description;
        payload["how"]=here.how;
        payload["id"]=here.id;
        payload["image_urls"]=[here.image_urls];
        payload["relatedMemories"]=here.relatedMemories;
        payload["subject"]=here.subject;
        payload["summary"]=here.summary;
        payload["when"]=here.when;
        payload["where"]=here.where;
        payload["who"]=here.who;

        memory_list.list::append(payload);
    }
    with exit{
        report memory_list;

    }

}

walker get_memory {
    has id;
    has payload={};
    has memory_list = [];

    root: take -[memories]-> node::memories else{
        report:custom = "no memories found";
    }
    memories: take -[memory(id==id)]-> node::memory;
    memory{
        payload["category"]="";
        payload["date_created"]=here.date_created;
        payload["date_modified"]=here.date_modified;
        payload["description"]=here.description;
        payload["how"]=here.how;
        payload["id"]=here.id;
        payload["image_urls"]=[here.image_urls];
        payload["relatedMemories"]=here.relatedMemories;
        payload["subject"]=here.subject;
        payload["summary"]=here.summary;
        payload["when"]=here.when;
        payload["where"]=here.where;
        payload["who"]=here.who;

    }
    with exit{
        report payload;

    }
} 

walker create_memory{
    has memory_context;
    has image_urls;
    has subject_title;
    // has sentiments = file.load_json(global.sentiments_path);
    has gs_description;
    has local_sentiments ={};

    can tobu.phrase_to_date;

    root: take -[memories]-> node::memories else{
        spawn here +[memories]+> node::memories;
        take -[memories]-> node::memories;
    }
    memories{
        payload ={};
        if(memory_context){


            memory_id = rand.word() + (rand.integer(0, 99999)).str;


            // for item in memory_context{
            //     if(memory_context['queue_context'][item].type == dict){
            //         if('date' in memory_context){
            //             payload["when"] = tobu.phrase_to_date(memory_context['date']);
            //         }
            //         else: payload["date"] = ["Date was not stated"];
            //         if('emotion' in memory_context){
            //             em = memory_context['emotion'];
            //             best_answer = use.text_classify(
            //                 text = em,
            //                 classes = visitor.sentiments_json.dict::keys
            //             );
            //             payload["how"] = best_answer.match;
            //         }
            //         else: payload["how"] = ["Emotion was not stated"];
            //         if('location' in memory_context){
            //             payload["where"] = [memory_context['location']];
            //         }
            //         else: payload["where"] = ["location was not stated"];
            //         if('people' in memory_context){
            //             payload["who"] = [memory_context['people']];
            //         }
            //         else: payload["who"] = ["People was not stated"];
            //     }
            //     elif(memory_context.type == list){
            //         if('date' in memory_context){
            //             payload["when"] = tobu.phrase_to_date(memory_context['date']);
            //         }
            //         else: payload["date"] = ["Date was not stated"];

            //         if('emotion' in memory_context){
            //             em = memory_context['emotion'];

            //             best_answer = use.text_classify(
            //                 text = em,
            //                 classes = visitor.sentiments_json.dict::keys
            //             );
            //             payload["how"] = best_answer.match;
            //         }
            //         else: payload["how"] = ["Emotion was not stated"];
            //         if('location' in memory_context){
            //             payload["where"] = [memory_context['location']];
            //         }
            //         else: payload["where"] = ["location was not stated"];
            //         if('people' in memory_context){
            //             payload["who"] = [memory_context['people']];
            //         }
            //         else: payload["who"] = ["People was not stated"];
            //     }
            // }

            if('date' in memory_context){
                payload["when"] = tobu.phrase_to_date(memory_context['date']);
            }
            else: payload["when"] = ["Date was not stated"];
            if('emotion' in memory_context){
                em = memory_context['emotion'];
                best_answer = use.text_classify(
                    text = em,
                    classes = local_sentiments.dict::keys
                );
                payload["how"] = best_answer.match;
            }
            else: payload["how"] = ["Emotion was not stated"];
            if('location' in memory_context){
                payload["where"] = [memory_context['location']];
            }
            else: payload["where"] = ["location was not stated"];
            if('people' in memory_context){
                payload["who"] = [memory_context['people']];
            }
            else: payload["who"] = ["People was not stated"];

            // for item in memory_context['queue_context']{
            payload["date_modified"] = date.datetime_now();
            payload["date_created"] = date.datetime_now();
            payload["id"]= memory_id;
            payload['summary'] = memory_context['summary'];
            
            payload['category'] = "";
            payload["subject"] = subject_title;
            payload["file_ids"] = "";
            payload["description"] = gs_description;
            payload["relatedMemories"] = [];
            

            if(image_urls){
                payload['image_urls'] = image_urls[0];
                nd = spawn node::memory(id=payload.id, subject=payload.subject, category=payload.category, summary=payload.summary, description=payload.description, when= payload.when, how=payload.how, who=payload.who, where=payload.where, file_ids=payload.file_ids, date_created = payload.date_created, date_modified= payload.date_modified, image_urls=payload.image_urls, relatedMemories=payload.relatedMemories);
                here +[memory(id=payload.id)]+> nd;
            }
            else{
                nd = spawn node::memory(id=payload.id, subject=payload.subject, category=payload.category, summary=payload.summary, description=payload.description, when= payload.when, how=payload.how, who=payload.who, where=payload.where, file_ids=payload.file_ids, date_created = payload.date_created, date_modified= payload.date_modified, relatedMemories=payload.relatedMemories);
                here +[memory(id=payload.id)]+> nd;
            }
        }

    }
}

walker update_memory {
    has id;
    has subject;
    has category; 
    has summary;
    has description;
    has when;
    has what;
    has how;
    has who;
    has where;
    has file_ids;
    has image_urls;

    has date_created;
    has date_modified;

    has everyone = [];

    root: take -[memories]-> node::memories else{
        report:custom = "no memories found";
    }
    memories: take -[memory(id==id)]-> node::memory;
    memory{
        here.date_modified = date.datetime_now();

        if(date_created): here.date_created = date_created;
        if(subject): here.subject = subject;
        if(category): here.category = category;
        if(summary): here.summary = summary;
        if(description): here.description = description;
        if(when): here.when = when;
        if(what): here.what = what;
        if(how): here.how = how;
        
        if(where): here.where = where;
        if(file_ids): here.file_ids = file_ids;
        if(image_urls):here.image_urls = image_urls;
    }

}

walker delete_memory {
    has id;
    root: take -[memories]-> node::memories else{
        report:custom = "no memories found";
    }
    memories: take -[memory(id==id)]-> node::memory;
    memory {
        report here;
        destroy here;
        disengage;
    }
}

node memory {
    has id;
    has subject;
    has category; 
    has summary;
    has description;
    has when;
    has what;
    has how;
    has who;
    has where;
    has file_ids = null;
    has date_created;
    has date_modified;
    has image_urls = null;
    has relatedMemories;
}

walker upload_files {
    has memory;
    has files;
    has id;

    has uploads = [];

    root: take -[memories]-> node::memories else{
        report:custom = "no memories found";
    }
    memories: take -[memory(id==id)]-> node::memory;
    memory{
        std.out(files);
        std.out(id);
    }

    // root: take --> node::upload_dir;

    upload_dir {
        for f in files {
            if('name' in f){
                rand_id = rand.word() + (rand.integer(0, 99999999)).str;
                // file.dump_from_b64(f['name'], f['base64']);
                res = spawn here +[upload_link(file_id=rand_id)]+> node::file(id=rand_id, name=f['name'], url=f['url']);
                res.context.id = &(res); 
                res.context.intial_id = rand_id; 
                uploads.list::append(res);
            }
        }
    }


    with exit {
        report uploads;
    }
}
