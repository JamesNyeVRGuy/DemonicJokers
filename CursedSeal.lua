--- STEAMODDED HEADER
--- MOD_NAME: CursedSeal
--- MOD_ID: CursedSeal
--- MOD_AUTHOR: [Your Name]
--- MOD_DESCRIPTION: Adds a Cursed seal
--- MOD_VERSION: 1.0.0

----------------------------------------------
------------MOD CODE -------------------------

function SMODS.INIT.CursedSeal()
    -- Register our Cursed seal with a simple approach
    SMODS.Seal:new(
            "Cursed",                      -- Name
            "Cursed",                      -- Key
            function(self, context)        -- Apply function (custom behavior)
                -- Only apply effect when the card is played
                if context.cardarea == G.play then
                    -- 50% chance to trigger the negative effect
                    if pseudorandom('cursed_seal') < 0.5 then
                        -- Count the number of 6s in the deck
                        local sixes_count = 0
                        for _, card in ipairs(G.playing_cards) do
                            if card:get_id() == 6 then
                                sixes_count = sixes_count + 1
                            end
                        end

                        -- Only apply effect if there are 6s in the deck
                        if sixes_count > 0 then
                            -- Show the effect message
                            card_eval_status_text(context.card, 'extra', nil, nil, nil, {
                                message = "CURSED: -$" .. sixes_count,
                                colour = G.C.RED
                            })

                            -- Add visual effect
                            context.card:juice_up(0.3, 0.3)
                            play_sound('tarot1', 0.9, 0.8)

                            -- Apply the money loss
                            ease_dollars(-sixes_count)

                            return {
                                message = "CURSED!",
                                colour = G.C.RED
                            }
                        end
                    end
                end
                return nil
            end,
            {                              -- Description
                "{C:red}50% chance{} to lose {C:money}$X{} when",
                "played, where X is the number of",
                "{C:attention}6{} cards in your deck"
            },
            { x = 0, y = 0 },              -- Position - using a standard position
            G.C.RED,                       -- Main color
            G.C.DARK_GREY,                 -- Glow color
            true,                          -- Available from start
            nil,                           -- Use default atlas
            { 1, 1, 1, 1, 1 }              -- Rarity chances
    ):register()

    -- Add localization entry
    G.localization.misc.dictionary.k_seal_cursed = "CURSED!"
end

----------------------------------------------
------------MOD CODE END----------------------