walker train_module{
    can sbert_sim.train;
    has train_data= [
                    ["A person is on a baseball team.","A person is playing basketball on a team.",0.99],
                    ["Our current vehicles will be in museums when everyone has their own aircraft.","The car needs to some work",0.99],
                    ["A woman supervisor is instructing the male workers.","A woman is working as a nurse.",0.99]
                ];
    report sbert_sim.train(train_data,{'num_epochs':2});
}


walker get_sim_score{
    can sbert_sim.get_text_sim;
    report sbert_sim.get_text_sim("girl dancing on a sandy beach.","A girl is on a sandy beach.",1);
}


// walker run train_module
// walker run get_sim_score