execute as @a[scores={legendaryspawnaction=1..}] at @s run function legendarysummoning:legendaryspawn

execute as @a if score @s timer_legsummons matches ..2000 run scoreboard players add @s timer_legsummons 1

execute as @a if score @s timer_legsummons matches 300.. run scoreboard players set @s whichLegendary 0

#articuno
execute as @a if score @s whichLegendary matches 1 if score @s timer_legsummons matches 100 run function legendarysummoning:articuno/spawn
execute as @a if score @s whichLegendary matches 1 if score @s timer_legsummons matches ..100 as @s at @s run particle snowflake ~ ~ ~ 8 8 8 10 100
execute as @a if score @s whichLegendary matches 1 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:move.haze.actor master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 1 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:pokemon_absol_cry master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 1 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#zapdos
execute as @a if score @s whichLegendary matches 2 if score @s timer_legsummons matches 100 run function legendarysummoning:zapdos/spawn
execute as @a if score @s whichLegendary matches 2 if score @s timer_legsummons matches ..100 as @s at @s run particle campfire_signal_smoke ~ ~20 ~ 10 1 10 0 100
execute as @a if score @s whichLegendary matches 2 if score @s timer_legsummons matches 101 as @s at @s run playsound minecraft:entity.lightning_bolt.thunder master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 2 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:pokemon_jolteon_cry master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 2 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#moltres
execute as @a if score @s whichLegendary matches 3 if score @s timer_legsummons matches 100 run function legendarysummoning:moltres/spawn
execute as @a if score @s whichLegendary matches 3 if score @s timer_legsummons matches ..100 as @s at @s run particle campfire_signal_smoke ~ ~ ~ 10 1 10 0 100
execute as @a if score @s whichLegendary matches 3 if score @s timer_legsummons matches 101 as @s at @s run playsound minecraft:entity.dragon_fireball.explode master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 3 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:pokemon_heatmor_cry master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 3 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#rayquaza
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 100 run function legendarysummoning:rayquaza/spawn
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 10 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.5
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 30 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.5
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 50 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.5
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 65 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.6
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 74 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.65
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 84 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.7
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 90 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.75
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 94 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.8
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 98 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 0.9
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 99 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 1
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 100 as @s at @s run playsound block.amethyst_block.resonate master @a ~ ~ ~ 100 1
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches ..100 as @s at @s run particle dripping_obsidian_tear ~ ~10 ~ 20 20 20 0 40
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 101 as @s at @s run playsound entity.ender_dragon.growl master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 4 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#regirock
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 100 run function legendarysummoning:regirock/spawn
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches ..100 as @s at @s run particle block{block_state:{Name:stone}} ~ ~ ~ 10 0 10 1 100 normal @a
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 0 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 20
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 20 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 40
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 40 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 60
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 60 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 80
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 80 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 90
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 100 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 101 as @s at @s run playsound minecraft:entity.dragon_fireball.explode master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:pokemon_heatmor_cry master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 5 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#regirock
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 100 run function legendarysummoning:regice/spawn
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches ..100 as @s at @s run particle block{block_state:{Name:blue_ice}} ~ ~ ~ 10 0 10 1 100 normal @a
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 0 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 20
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 20 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 40
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 40 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 60
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 60 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 80
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 80 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 90
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 100 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 101 as @s at @s run playsound minecraft:entity.dragon_fireball.explode master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:pokemon_heatmor_cry master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 6 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#registeel
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 100 run function legendarysummoning:registeel/spawn
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches ..100 as @s at @s run particle block{block_state:{Name:iron_block}} ~ ~ ~ 10 0 10 1 100 normal @a
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 0 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 20
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 20 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 40
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 40 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 60
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 60 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 80
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 80 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 90
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 100 as @s at @s run playsound minecraft:entity.zombie.break_wooden_door master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 101 as @s at @s run playsound minecraft:entity.dragon_fireball.explode master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:pokemon_heatmor_cry master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 7 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#koraidon
execute as @a if score @s whichLegendary matches 8 if score @s timer_legsummons matches 100 run function legendarysummoning:koraidon/spawn
# animazione: execute as @a if score @s whichLegendary matches 8 if score @s timer_legsummons matches ..100 as @s at @s run particle snowflake ~ ~ ~ 8 8 8 10 100
# suono: execute as @a if score @s whichLegendary matches 8 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:move.haze.actor master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 8 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:pokemon_mightyena_cry master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 8 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#miraidon
execute as @a if score @s whichLegendary matches 9 if score @s timer_legsummons matches 100 run function legendarysummoning:miraidon/spawn
# animazione: execute as @a if score @s whichLegendary matches 9 if score @s timer_legsummons matches ..100 as @s at @s run particle snowflake ~ ~ ~ 8 8 8 10 100
# suono: execute as @a if score @s whichLegendary matches 9 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:move.haze.actor master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 9 if score @s timer_legsummons matches 101 as @s at @s run playsound cobblemon:pokemon_mightyena_cry master @a ~ ~ ~ 100
execute as @a if score @s whichLegendary matches 9 if score @s timer_legsummons matches 101.. run scoreboard players set @s whichLegendary 0

#craft mystical sandwich
#execute at @a as @e[type=item,distance=..5,nbt={OnGround:true,Item:{id:"minecraft:bread",count:1}},limit=1] at @s store success entity @s Age short 6000 store success entity @e[type=item,distance=...5,nbt={OnGround:true,Item:{id:"minecraft:porkchop",count:1}},limit=1] Age short 6000 at @s store success entity @s Age short 6000 store success entity @e[type=item,distance=...5,nbt={OnGround:true,Item:{id:"minecraft:carrot_on_a_stick",count:3,components:{"minecraft:custom_name":'{"text":"Herba Mystica"}',"minecraft:custom_model_data":3710009}}},limit=2] Age short 6000 run summon item ~ ~ ~ {Item:{id:"minecraft:carrot_on_a_stick",count:2,components:{"minecraft:custom_name":'{"text":"Mystical Sandwich"}',custom_model_data:3710008}}}
execute at @a as @e[type=item,distance=..5,nbt={OnGround:true,Item:{id:"minecraft:bread",count:2}},limit=2] at @s store success entity @s Age short 6000 store success entity @e[type=item,distance=...5,nbt={OnGround:true,Item:{id:"minecraft:carrot_on_a_stick",components:{"minecraft:custom_model_data":3710009},count:1}},limit=1] Age short 6000 run summon item ~ ~ ~ {Item:{id:"minecraft:carrot_on_a_stick",count:1,components:{"minecraft:item_name":'{"text":"Mystical Sandwich"}',custom_model_data:3710008}}}