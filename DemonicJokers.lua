--- STEAMODDED HEADER
--- MOD_NAME: DemonJokers
--- MOD_ID: DemonJokers
--- MOD_AUTHOR: [Evil Coder]
--- MOD_DESCRIPTION: Dark and evil rituals for your cards and jokers
--- MOD_VERSION: 1.0.1

----------------------------------------------
------------MOD CODE -------------------------
-- Fixed version to address crash when accessing G.jokers before it's initialized

local jokers = {
    pentagramjoker = {
        name = "Pentagram Joker",
        text = {
            "Sacrifice {C:red}#3# chips{} to",
            "increase scored card values by {C:attention}#1#{}", 
            "{C:inactive}(unholy ritual){}"
        },
        config = { extra = { value_boost = 3, x_mult = 0, sacrifice = 25 } },
        pos = { x = 0, y = 0 },
        rarity = 2,
        cost = 6,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.individual and context.cardarea == G.play then
                if G.GAME.chips >= self.ability.extra.sacrifice then
                    ease_chips(-self.ability.extra.sacrifice)
                    card_eval_status_text(self, 'extra', nil, nil, nil, {message = "SACRIFICED", colour = G.C.RED})
                    
                    return {
                        value = self.ability.extra.value_boost,
                        card = self,
                        message = localize { type = 'variable', key = 'a_value', vars = { self.ability.extra.value_boost } }
                    }
                end
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.value_boost, self.ability.extra.x_mult, self.ability.extra.sacrifice }
        end,
    },

    soulstealerjoker = {
        name = "Soul Stealer",
        text = {
            "For each {C:attention}Joker{} destroyed in this run,",
            "gives {C:mult}+#1# mult{} and {X:red,C:white}X#3#{} mult", 
            "{C:inactive}(currently: #2# mult & X#4# mult){}",
            "{C:red}(debug: Gains power from destroyed jokers){}",
        },
        config = { extra = { mult_per_soul = 1, total_mult = 0, xmult_per_soul = 0.1, total_xmult = 1 } },
        pos = { x = 0, y = 0 },
        rarity = 3,
        cost = 8,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            -- Get the count of destroyed jokers safely
            local destroyed_count = (G.GAME and G.GAME.jokers_destroyed) or 0
            
            self.ability.extra.total_mult = destroyed_count * self.ability.extra.mult_per_soul
            self.ability.extra.total_xmult = 1 + (destroyed_count * self.ability.extra.xmult_per_soul)
            
            if SMODS.end_calculate_context(context) then
                return {
                    mult_mod = self.ability.extra.total_mult,
                    Xmult_mod = self.ability.extra.total_xmult,
                    card = self,
                    message = localize { type = 'variable', key = 'a_mult_x', vars = { self.ability.extra.total_mult, self.ability.extra.total_xmult } }
                }
            end
        end,

        loc_def = function(self)
            -- Get destroyed jokers count safely
            local souls = (G.GAME and G.GAME.jokers_destroyed) or 0
            return { 
                self.ability.extra.mult_per_soul, 
                souls * self.ability.extra.mult_per_soul, 
                self.ability.extra.xmult_per_soul,
                1 + (souls * self.ability.extra.xmult_per_soul)
            }
        end,
    },

    cursejoker = {
        name = "Curse Joker",
        text = {
            "{C:green}#3# in #4#{} chance of converting",
            "scored {C:attention}numbered cards{} to {C:attention}value 1{}", 
            "but gives {C:mult}+#1# mult{} for each",
            "{C:red}(debug: Converts cards to 1s but gives mult){}",
        },
        config = { extra = { mult_per_card = 2, x_mult = 0, odds = 3, normal = 1 } },
        pos = { x = 0, y = 0 },
        rarity = 2,
        cost = 5,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.individual and context.cardarea == G.play then
                if context.other_card:get_id() <= 10 then -- numbered cards only
                    if pseudorandom('cursejoker') < G.GAME.probabilities.normal/self.ability.extra.odds then
                        context.other_card.base.value = 1
                        card_eval_status_text(self, 'extra', nil, nil, nil, {message = "CURSED", colour = G.C.RED})
                        
                        return {
                            mult = self.ability.extra.mult_per_card,
                            card = self,
                            message = localize { type = 'variable', key = 'a_mult', vars = { self.ability.extra.mult_per_card } }
                        }
                    end
                end
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.mult_per_card, self.ability.extra.x_mult, G.GAME.probabilities.normal, self.ability.extra.odds }
        end,
    },

    bloodpactjoker = {
        name = "Blood Pact",
        text = {
            "After each {C:attention}blind{},",
            "{C:red}destroy{} the most valuable {C:attention}card in hand{}",
            "and gain {C:mult}+#1# mult{} next hand",
            "{C:red}(debug: Destroys cards but gives mult boost){}",
        },
        config = { extra = { sacrifice_mult = 6, pending_mult = 0 } },
        pos = { x = 0, y = 0 },
        rarity = 3,
        cost = 7,
        blueprint_compat = false,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.end_of_round and not context.individual and not context.blueprint then
                -- Find highest value card in hand
                local highest_value = 0
                local highest_card = nil
                
                for i, card in ipairs(G.hand.cards) do
                    if card.base.value > highest_value then
                        highest_value = card.base.value
                        highest_card = card
                    end
                end
                
                if highest_card then
                    -- Destroy the card with visual effect
                    highest_card:juice_up(0.3, 0.4)
                    highest_card.T.r = -0.2
                    
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.3,
                        func = function() 
                            highest_card:start_dissolve()
                            play_sound('tarot1')
                            return true
                        end
                    }))
                    
                    -- Set up mult boost for next hand
                    self.ability.extra.pending_mult = self.ability.extra.sacrifice_mult
                    card_eval_status_text(self, 'extra', nil, nil, nil, {message = "BLOOD SACRIFICE", colour = G.C.RED})
                end
            end
            
            if SMODS.end_calculate_context(context) then
                if self.ability.extra.pending_mult > 0 then
                    local return_val = {
                        mult_mod = self.ability.extra.pending_mult,
                        card = self,
                        message = localize { type = 'variable', key = 'a_mult', vars = { self.ability.extra.pending_mult } }
                    }
                    self.ability.extra.pending_mult = 0
                    return return_val
                end
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.sacrifice_mult }
        end,
    },

    demonicritualjoker = {
        name = "Demonic Ritual",
        text = {
            "At the start of each {C:attention}round{}, choose",
            "between {C:mult}+#1# mult{}, {C:chips}+#2# chips{},",
            "or {C:attention}+1 hand size{} for this round",
            "{C:red}(debug: Offers choices at start of round){}",
        },
        config = { extra = { mult_option = 5, chip_option = 50, used_this_round = false } },
        pos = { x = 0, y = 0 },
        rarity = 2,
        cost = 6,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if G.GAME.current_round.name ~= self.last_round_name and not self.ability.extra.used_this_round then
                self.last_round_name = G.GAME.current_round.name
                self.ability.extra.used_this_round = true
                
                -- Create a ritual choice
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.1,
                    func = function()
                        -- Prevent UI overlap
                        if G.CONTROLLER.minigame_active then return false end
                        
                        local options = {
                            {
                                id = 'mult',
                                text = localize{type='variable',key='a_mult',vars={self.ability.extra.mult_option}},
                                btn_func = function()
                                    -- Apply the mult boost
                                    self.temp_mult = self.ability.extra.mult_option
                                    card_eval_status_text(self, 'extra', nil, nil, nil, {message = "DARK POWER", colour = G.C.RED})
                                end
                            },
                            {
                                id = 'chips',
                                text = localize{type='variable',key='a_chips',vars={self.ability.extra.chip_option}},
                                btn_func = function()
                                    -- Give chips
                                    ease_chips(self.ability.extra.chip_option)
                                    card_eval_status_text(self, 'extra', nil, nil, nil, {message = "BLOOD MONEY", colour = G.C.RED})
                                end
                            },
                            {
                                id = 'handsize',
                                text = "+1 Hand Size",
                                btn_func = function()
                                    -- Increase hand size for this round only
                                    G.hand.config.card_limit = G.hand.config.card_limit + 1
                                    card_eval_status_text(self, 'extra', nil, nil, nil, {message = "RITUAL COMPLETE", colour = G.C.RED})
                                end
                            }
                        }
                        
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.1,
                            func = function()
                                create_UIBox_choice_dialog(
                                    options,
                                    "Choose Your Ritual",
                                    false
                                )
                                return true
                            end
                        }))
                        
                        return true
                    end
                }))
            end
            
            if context.end_of_round and not context.individual and not context.blueprint then
                -- Reset temporary effects at end of round
                if G.hand.config.card_limit > G.hand.config.card_limit_base then
                    G.hand.config.card_limit = G.hand.config.card_limit_base
                end
                self.ability.extra.used_this_round = false
                self.temp_mult = 0
            end
            
            if SMODS.end_calculate_context(context) and self.temp_mult and self.temp_mult > 0 then
                return {
                    mult_mod = self.temp_mult,
                    card = self
                }
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.mult_option, self.ability.extra.chip_option }
        end,
    },

    inversionsjoker = {
        name = "Inversion Joker",
        text = {
            "At beginning of {C:attention}each round{}, inverts",
            "values of all numbered cards in deck",
            "(1↔10, 2↔9, 3↔8, 4↔7, 5↔6)",
            "{C:red}(debug: Flips card values){}",
        },
        config = { extra = { mult = 0, x_mult = 0 } },
        pos = { x = 0, y = 0 },
        rarity = 2,
        cost = 5,
        blueprint_compat = false,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if G.GAME.current_round.name ~= self.last_round_name then
                self.last_round_name = G.GAME.current_round.name
                
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.5,
                    func = function()
                        -- Invert card values for all numbered cards in deck
                        for _, card in ipairs(G.deck.cards) do
                            local id = card:get_id()
                            if id <= 10 then -- Only invert numbered cards
                                local original_value = card.base.value
                                local new_id
                                
                                if id == 1 then new_id = 10
                                elseif id == 2 then new_id = 9
                                elseif id == 3 then new_id = 8
                                elseif id == 4 then new_id = 7
                                elseif id == 5 then new_id = 6
                                elseif id == 6 then new_id = 5
                                elseif id == 7 then new_id = 4
                                elseif id == 8 then new_id = 3
                                elseif id == 9 then new_id = 2
                                elseif id == 10 then new_id = 1
                                end
                                
                                if new_id then
                                    local suit_prefix = SMODS.Suits[card.base.suit].card_key .. '_'
                                    local rank_key
                                    
                                    if new_id == 1 then rank_key = "A"
                                    elseif new_id == 10 then rank_key = "T"
                                    else rank_key = tostring(new_id)
                                    end
                                    
                                    card:set_base(G.P_CARDS[suit_prefix .. rank_key])
                                    
                                    -- Visual effect
                                    card:juice_up(0.3, 0.3)
                                end
                            end
                        end
                        
                        card_eval_status_text(self, 'extra', nil, nil, nil, {message = "INVERTED", colour = G.C.RED})
                        play_sound('tarot1', 1, 0.8)
                        return true
                    end
                }))
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.mult, self.ability.extra.x_mult }
        end,
    },

    soulcollectorjoker = {
        name = "Soul Collector",
        text = {
            "Gain {C:attention}1 soul{} when face cards are played",
            "Spend {C:attention}5 souls{} to {C:mult}double{} the",
            "value of a randomly played face card",
            "{C:red}(debug: Collects souls, doubles card values){}",
        },
        config = { extra = { souls = 0, souls_needed = 5 } },
        pos = { x = 0, y = 0 },
        rarity = 3,
        cost = 7,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.individual and context.cardarea == G.play then
                local id = context.other_card:get_id()
                
                -- Collect souls from face cards
                if id == 11 or id == 12 or id == 13 then
                    self.ability.extra.souls = self.ability.extra.souls + 1
                    card_eval_status_text(self, 'extra', nil, nil, nil, {message = "SOUL CLAIMED", colour = G.C.RED})
                end
                
                -- Use souls to double face card value
                if (id == 11 or id == 12 or id == 13) and self.ability.extra.souls >= self.ability.extra.souls_needed then
                    if pseudorandom('soulcollector') < 0.5 then
                        self.ability.extra.souls = self.ability.extra.souls - self.ability.extra.souls_needed
                        context.other_card.base.value = context.other_card.base.value * 2
                        
                        -- Visual effect
                        context.other_card:juice_up(0.5, 0.5)
                        play_sound('tarot1', 1, 0.6)
                        
                        card_eval_status_text(self, 'extra', nil, nil, nil, {message = "RITUAL COMPLETE", colour = G.C.RED})
                        return {
                            message = localize { "SOULS CONSUMED" }
                        }
                    end
                end
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.souls, self.ability.extra.souls_needed }
        end,
    },

    devilspactjoker = {
        name = "Devil's Pact",
        text = {
            "Every {C:attention}third discard{}, choose a card",
            "to {C:red}permanently sacrifice{} from your hand",
            "and gain {C:mult}+#1# mult{} for the rest of the run",
            "{C:red}(debug: Sacrifice cards for permanent mult){}",
        },
        config = { extra = { perm_mult = 7, discard_count = 0, gained_mult = 0 } },
        pos = { x = 0, y = 0 },
        rarity = 3,
        cost = 9,
        blueprint_compat = false,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.discard and context.other_card == context.full_hand[#context.full_hand] and not context.blueprint then
                self.ability.extra.discard_count = self.ability.extra.discard_count + 1
                
                if self.ability.extra.discard_count >= 3 then
                    self.ability.extra.discard_count = 0
                    
                    -- Create card sacrifice choice
                    G.E_MANAGER:add_event(Event({
                        trigger = 'after',
                        delay = 0.4,
                        func = function()
                            -- Prevent UI overlap
                            if G.CONTROLLER.minigame_active then return false end
                            
                            local options = {}
                            local cards_in_hand = {}
                            
                            -- Create options for each card in hand
                            for i, card in ipairs(G.hand.cards) do
                                table.insert(cards_in_hand, card)
                                
                                local card_name = ""
                                if card.base.suit == "Hearts" then card_name = "♥ "
                                elseif card.base.suit == "Diamonds" then card_name = "♦ "
                                elseif card.base.suit == "Clubs" then card_name = "♣ "
                                elseif card.base.suit == "Spades" then card_name = "♠ "
                                end
                                
                                local rank = card:get_id()
                                if rank == 1 then card_name = card_name .. "A"
                                elseif rank == 11 then card_name = card_name .. "J"
                                elseif rank == 12 then card_name = card_name .. "Q"
                                elseif rank == 13 then card_name = card_name .. "K"
                                else card_name = card_name .. tostring(rank)
                                end
                                
                                table.insert(options, {
                                    id = 'card_' .. i,
                                    text = "Sacrifice " .. card_name,
                                    btn_func = function()
                                        -- Sacrifice the card with visual effect
                                        card:juice_up(0.3, 0.4)
                                        card.T.r = -0.2
                                        
                                        G.E_MANAGER:add_event(Event({
                                            trigger = 'after',
                                            delay = 0.3,
                                            func = function() 
                                                G.hand:remove_card(card)
                                                card:start_dissolve()
                                                play_sound('tarot1')
                                                
                                                -- Add permanent mult
                                                self.ability.extra.gained_mult = self.ability.extra.gained_mult + self.ability.extra.perm_mult
                                                card_eval_status_text(self, 'extra', nil, nil, nil, {message = "SOUL CLAIMED", colour = G.C.RED})
                                                return true
                                            end
                                        }))
                                    end
                                })
                            end
                            
                            G.E_MANAGER:add_event(Event({
                                trigger = 'after',
                                delay = 0.1,
                                func = function()
                                    create_UIBox_choice_dialog(
                                        options,
                                        "Choose a Card to Sacrifice",
                                        false
                                    )
                                    return true
                                end
                            }))
                            
                            return true
                        end
                    }))
                end
            end
            
            if SMODS.end_calculate_context(context) and self.ability.extra.gained_mult > 0 then
                return {
                    mult_mod = self.ability.extra.gained_mult,
                    card = self,
                    message = localize { type = 'variable', key = 'a_mult', vars = { self.ability.extra.gained_mult } }
                }
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.perm_mult, self.ability.extra.gained_mult, self.ability.extra.discard_count }
        end,
    },

    hellhoundjoker = {
        name = "Hellhound",
        text = {
            "At the end of each {C:attention}round{},",
            "{C:red}destroys{} another random {C:attention}Joker{}",
            "and gains its power ({C:mult}+#1# mult{} per Joker)",
            "{C:red}(debug: Consumes other jokers for power){}",
        },
        config = { extra = { mult_per_joker = 3, total_mult = 0, consumed_jokers = 0 } },
        pos = { x = 0, y = 0 },
        rarity = 4,
        cost = 12,
        blueprint_compat = false,
        eternal_compat = false,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.end_of_round and not context.individual and not context.blueprint then
                -- Only consume jokers if there are other jokers to consume
                if #G.jokers.cards > 1 then
                    -- Get list of other jokers
                    local other_jokers = {}
                    for i, card in ipairs(G.jokers.cards) do
                        if card ~= self then
                            table.insert(other_jokers, card)
                        end
                    end
                    
                    if #other_jokers > 0 then
                        -- Choose a random joker to consume
                        local random_index = math.random(1, #other_jokers)
                        local joker_to_consume = other_jokers[random_index]
                        
                        -- Visual effect
                        joker_to_consume:juice_up(0.3, 0.4)
                        joker_to_consume.T.r = -0.2
                        
                        G.E_MANAGER:add_event(Event({
                            trigger = 'after',
                            delay = 0.3,
                            func = function() 
                                joker_to_consume:start_dissolve()
                                G.jokers:remove_card(joker_to_consume)
                                play_sound('tarot1')
                                
                                -- Track destroyed joker
                                if not G.GAME.jokers_destroyed then G.GAME.jokers_destroyed = 0 end
                                G.GAME.jokers_destroyed = G.GAME.jokers_destroyed + 1
                                
                                -- Gain power
                                self.ability.extra.consumed_jokers = self.ability.extra.consumed_jokers + 1
                                self.ability.extra.total_mult = self.ability.extra.consumed_jokers * self.ability.extra.mult_per_joker
                                
                                card_eval_status_text(self, 'extra', nil, nil, nil, {message = "CONSUMED", colour = G.C.RED})
                                return true
                            end
                        }))
                    end
                end
            end
            
            if SMODS.end_calculate_context(context) and self.ability.extra.total_mult > 0 then
                return {
                    mult_mod = self.ability.extra.total_mult,
                    card = self,
                    message = localize { type = 'variable', key = 'a_mult', vars = { self.ability.extra.total_mult } }
                }
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.mult_per_joker, self.ability.extra.total_mult, self.ability.extra.consumed_jokers }
        end,
    },

    voodoojoker = {
        name = "Voodoo Joker",
        text = {
            "Place {C:attention}pins{} in random played cards",
            "Each pin gives {C:chips}+#1# chips{} but",
            "reduces card's {C:attention}value by 1{}",
            "{C:red}(debug: Places pins in cards for chips){}",
        },
        config = { extra = { chips_per_pin = 15, pin_chance = 0.3 } },
        pos = { x = 0, y = 0 },
        rarity = 2,
        cost = 4,
        blueprint_compat = true,
        eternal_compat = true,
        unlocked = true,
        discovered = true,
        atlas = nil,
        soul_pos = nil,

        calculate = function(self, context)
            if context.individual and context.cardarea == G.play and not context.blueprint then
                if pseudorandom('voodoojoker') < self.ability.extra.pin_chance then
                    -- Place a pin in the card
                    if context.other_card.base.value > 1 then
                        context.other_card.base.value = context.other_card.base.value - 1
                        
                        -- Visual effect
                        context.other_card:juice_up(0.3, 0.3)
                        play_sound('tarot1', 1, 1.2)
                        
                        card_eval_status_text(self, 'extra', nil, nil, nil, {message = "PIN PLACED", colour = G.C.RED})
                        
                        return {
                            chip_mod = self.ability.extra.chips_per_pin,
                            card = self,
                            message = localize { type = 'variable', key = 'a_chips', vars = { self.ability.extra.chips_per_pin } }
                        }
                    end
                end
            end
        end,

        loc_def = function(self)
            return { self.ability.extra.chips_per_pin }
        end,
    },
}

function SMODS.INIT.DemonJokers()
    -- Initialize localization if needed
    -- init_localization()

    -- Initialize jokers_destroyed counter if it doesn't exist
    if not G.GAME then G.GAME = {} end
    if not G.GAME.jokers_destroyed then G.GAME.jokers_destroyed = 0 end

    -- Create and register jokers
    for k, v in pairs(jokers) do
        local joker = SMODS.Joker:new(v.name, k, v.config, v.pos, { name = v.name, text = v.text }, v.rarity, v.cost,
            v.unlocked, v.discovered, v.blueprint_compat, v.eternal_compat, v.effect, v.atlas, v.soul_pos)
        joker:register()

        -- Use built-in sprites instead of custom ones
        if k == "pentagramjoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_joker"  -- Red joker for Pentagram
        elseif k == "soulstealerjoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_gros_michel"  -- Blue ghost-like joker for Soul Stealer
        elseif k == "cursejoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_misprint"  -- Curse Joker 
        elseif k == "bloodpactjoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_fibonacci"  -- Blood red spiral for Blood Pact
        elseif k == "demonicritualjoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_ceremonial"  -- Ceremonial/ritual themed
        elseif k == "inversionsjoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_mirror"  -- Mirror effect for inversion
        elseif k == "soulcollectorjoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_ghost"  -- Ghost for soul collector
        elseif k == "devilspactjoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_red"  -- Red for devil
        elseif k == "hellhoundjoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_cerberus"  -- Cerberus for hellhound
        elseif k == "voodoojoker" then
            SMODS.Jokers[joker.slug].sprite_name = "j_lucky_cat"  -- Pin-cushion like for voodoo
        else
            SMODS.Jokers[joker.slug].sprite_name = "j_joker"  -- Default fallback
        end

        -- Add jokers calculate function
        SMODS.Jokers[joker.slug].calculate = v.calculate
        
        -- Add jokers loc_def
        SMODS.Jokers[joker.slug].loc_def = v.loc_def
        
        -- Add tooltip if present
        if (v.tooltip ~= nil) then
            SMODS.Jokers[joker.slug].tooltip = v.tooltip
        end
    end
    
    -- Create sprite atlas if needed
    -- SMODS.Sprite:new("demonjokers_atlas", SMODS.findModByID("DemonJokers").path, "demonjokers.png", 71, 95, "asset_atli")
    --    :register()
    
    -- Patch into destroy joker functionality to track souls for Soul Stealer
    -- We need to make sure G.jokers exists before trying to patch it
    G.GAME.after_joker_init = function()
        if G.jokers then
            local old_remove_joker = G.jokers.remove_card
            G.jokers.remove_card = function(self, card)
                if not G.GAME.jokers_destroyed then G.GAME.jokers_destroyed = 0 end
                
                -- Don't count hellhound's consumption as it already does
                local called_by_hellhound = false
                local traceback_str = debug.traceback()
                if traceback_str:find("hellhoundjoker") then
                    called_by_hellhound = true
                end
                
                if not called_by_hellhound then
                    G.GAME.jokers_destroyed = G.GAME.jokers_destroyed + 1
                end
                
                return old_remove_joker(self, card)
            end
        end
    end
    
    -- Hook into the game's initialization to ensure jokers are available
    local old_init_run = G.INIT_RUN
    G.INIT_RUN = function(...)
        local result = old_init_run(...)
        if G.GAME.after_joker_init then G.GAME.after_joker_init() end
        return result
    end
end

----------------------------------------------
------------MOD CODE END----------------------