
edge dialog;
edge user;


edge intent_transition {
    has intent;
}

edge intent_transition_fixed {
    has intent;
}

edge redirect_transition {
    has name;
}

edge redirect_confirm_transition {
    has name;
}

edge entity_transition {
    has entities;
}

edge faqs;
edge faq;


// tobu

edge memories;
edge memory: has id;

node memories;
