


SMODS.Atlas {
    -- Key for code to find it with
    key = "joker-sprites",
    -- The name of the file, for the code to pull the atlas from
    path = "joker-sprites.png",
    -- Width of each sprite in 1x size
    px = 71,
    -- Height of each sprite in 1x size
    py = 95
  }

  function pseudorandom_elements(_t, seed, count)
    if count >= #_t then
      return _t
    end


    if seed then math.randomseed(seed) end

    local keys = {}
    for k, v in pairs(_t) do
        keys[#keys+1] = {k = k,v = v}
    end

    for i = #keys, 2, -1 do
      local j = math.random(i)
      keys[i], keys[j] = keys[j], keys[i]
    end
  
    local shuffled = {}
    for key, value in pairs({unpack(keys, 1, count)}) do
      shuffled[key] = value.v
    end
  
    return shuffled
  end
  

  local function random_destroy_many(used_joker, count)
    local destroyed_cards = {}
    destroyed_cards = pseudorandom_elements(G.hand.cards, pseudoseed('random_destroy'), count)

    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.4,
        func = function()
            play_sound('tarot1')
            used_joker:juice_up(0.3, 0.5)
            return true
        end
    }))
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.1,
        func = function()
            for i = #destroyed_cards, 1, -1 do
                local card = destroyed_cards[i]
                if card.ability.name == 'Glass Card' then
                    card:shatter()
                else
                    card:start_dissolve(nil, i ~= #destroyed_cards)
                end
            end
            return true
        end
    }))
    return destroyed_cards
  end




  local function generate_playing_cards(cards)
    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      delay = 0.4,
      func = function()
        local new_cards = {}
        local _first_dissolve = nil

        for i = #cards, 1, -1 do
          local _card = copy_card(cards[i], nil, nil, G.playing_card)
          _card:set_ability(G.P_CENTERS.m_mult, nil, true)
          _card:add_to_deck()
          G.deck.config.card_limit = G.deck.config.card_limit + 1
          table.insert(G.playing_cards, _card)
          G.deck:emplace(_card)
          _card:start_materialize(nil, _first_dissolve)
          _first_dissolve = true
          new_cards[#new_cards+1] = _card
        end
        playing_card_joker_effects(new_cards)

        return true
      end
    }))
  end




  SMODS.Joker {
    key = 'Epitaph Joker',
    loc_txt = {
      name = 'Epitaph Joker',
      text = {
        -- "Destroys {C:attention}#1#{} card#2# after each", 
        -- "played hand and gains {C:money}$#1#{} sell value", 
        -- "or {S:1.1,C:red,E:2}self destructs{}. Returns cards",
        -- "to deck with enhancements after",
        -- "{C:attention}#3#{} hands played."
        "Destroys cards after each ",
        "played hand and gains sell value.",
        "Returns cards to deck with",
        "enhancements after {C:attention}#3#{} hands played.",
        "{C:inactive,s:0.8}(Will destroy {s:0.8,C:attention}#1#{C:inactive,s:0.8} card#2# next hand){}"
      }
    },
    config = { 
        extra = { 
            consumed_cards = {},
            twilight = 1,
            sacrifices_per_twilight = {
                [1] = 6,
                [2] = 2,
                [3] = 0,
                [4] = 1,
                [5] = 1,
                [6] = 1,
                [7] = 1,
                [8] = 1,
                [9] = "all",
                [10] = 0
            },
            value_per_consumed = 1,
            base_sell_value = 3,
        
        } },
    loc_vars = function(self, info_queue, card)
      local sacrifices = card.ability.extra.sacrifices_per_twilight[card.ability.extra.twilight]
      if not sacrifices then sacrifices = 0 end
      return { vars = {
        sacrifices,
        (sacrifices ~= 1 and "s") or "",
        11 - card.ability.extra.twilight } }
    end,
    rarity = 2,
    atlas = 'joker-sprites',
    pos = { x = 0, y = 0 },
    cost = 6,
    calculate = function(self, card, context)

      if context.after and context.cardarea == G.jokers then 

        -- if (card.ability.extra.twilight == 1) then
        --   noCards = 6
        --   local destroyed_cards = random_destroy_many(card, noCards)
        --   for k, v in pairs(destroyed_cards) do
        --     card.ability.extra.consumed_cards[#card.ability.extra.consumed_cards + 1] = v
        --   end
        -- elseif (card.ability.extra.twilight == 2) then
        --   noCards = 2
        --   local destroyed_cards = random_destroy_many(card, noCards)
        --   for k, v in pairs(destroyed_cards) do
        --     card.ability.extra.consumed_cards[#card.ability.extra.consumed_cards + 1] = v
        --   end
        -- elseif (card.ability.extra.twilight >= 4 and card.ability.extra.twilight < 9) then
        --   noCards = 1
        --   local destroyed_cards = random_destroy_many(card, noCards)
        --   for k, v in pairs(destroyed_cards) do
        --     card.ability.extra.consumed_cards[#card.ability.extra.consumed_cards + 1] = v
        --   end
        -- elseif (card.ability.extra.twilight >= 4 and card.ability.extra.twilight == 9) then
        --   -- On the ninth twilight, the witch shall revive, and none shall be left alive.
        --   generate_playing_cards(card.ability.extra.consumed_cards)
        --   card.ability.extra.consumed_cards = {}

        -- end

        twilight = card.ability.extra.twilight
        
        if twilight < 10 then
          sacrifices = card.ability.extra.sacrifices_per_twilight[twilight]
          if sacrifices == 0 then 
            card.ability.extra.twilight = card.ability.extra.twilight + 1
            return {
              colour = G.C.JOKER_GREY,
              card = card
            }
   
          end
          if sacrifices == "all" then
            sacrifices = #G.hand.cards
          end
          destroyed_cards = random_destroy_many(card, sacrifices)
          card.ability.extra_value = card.ability.extra_value + (#destroyed_cards * card.ability.extra.value_per_consumed)
          for k, v in pairs(destroyed_cards) do
            card.ability.extra.consumed_cards[#card.ability.extra.consumed_cards + 1] = v
          end
          card.ability.extra.twilight = card.ability.extra.twilight + 1
        elseif twilight == 10 then
          generate_playing_cards(card.ability.extra.consumed_cards)
          card.ability.extra.consumed_cards = {}
          card.ability.extra.twilight = card.ability.extra.twilight + 1
        
        else
          return

        end
        card:set_cost()

        return {
            message = "Value Up!",
            colour = G.C.MONEY,
            card = card
          }
      end
    end
  }