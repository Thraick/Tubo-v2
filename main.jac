import {*} with "./walkers.jac";
import {*} with "./graphs.jac";
import {*} with "./globals.jac";

import {*} with './utils/model/kit/tfm_ner.jac';
import {*} with "./utils/model/kit/sbert.jac";


walker init {
    root{
        global.main_root = here.info["jid"];

        take -[dialog]-> node::dialog else{
            spawn here +[user]+> node::user;
            spawn here +[dialog]+> graph::dialogue_system;
            take -[dialog]-> node::dialog;
        }
    }
    dialog{
        global.dialogue_root = here.info['jid'];
    }
}

