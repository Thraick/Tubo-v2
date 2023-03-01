import {*} with "./nodes.jac";
import {*} with "./edges.jac";


graph dialogue_system {
    has anchor dialogue_root;
    spawn{
        classifier_json = file.load_json(global.classifier_path);
        dialogue_root = spawn node::dialog;

        document_memory = spawn node::document_memory(imprint = [{"list_imprint":classifier_json['document_memory'], "name": "document_memory"}], name="document_memory");
        capture_memories = spawn node::capture_memories(name="capture_memories");
        unanswered_queue = spawn node::unanswered_queue(name="unanswered_queue");
        additional_memory = spawn node::additional_memory(name="additional_memory");
        confirm_save_memory = spawn node::summary_template(imprint = [{"list_imprint":classifier_json['confirm_save_memory'], "name": "confirm_save_memory"}], name="confirm_save_memory");

        
        dialogue_root +[intent_transition(intent="document_memory")]+>document_memory;
        dialogue_root +[redirect_transition]+> capture_memories;

        document_memory +[redirect_transition]+> capture_memories;

        capture_memories +[intent_transition_fixed(intent="unanswered_queue")]+>unanswered_queue;
        capture_memories +[redirect_transition]+>additional_memory;
        capture_memories +[intent_transition(intent="confirm_save_memory")]+>confirm_save_memory;

        additional_memory +[intent_transition(intent="confirm_save_memory")]+>confirm_save_memory;
        additional_memory +[redirect_transition]+>capture_memories;

        unanswered_queue +[intent_transition_fixed(intent="additional_memory")]+>additional_memory;
        unanswered_queue +[intent_transition(intent="confirm_save_memory")]+>confirm_save_memory;

        // unanswered_queue +[redirect_transition]+>capture_memories;



    }
}