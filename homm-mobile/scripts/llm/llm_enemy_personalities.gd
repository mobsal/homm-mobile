extends RefCounted

# Retourne un profil de personnalité pour un ennemi selon son index.
# On utilise l'index pour varier les personnalités (modulo sur une liste).

const _PERSONALITIES: Array[Dictionary] = [
	{
		"archetype": "Ronin désabusé",
		"personality": "Un samouraï sans maître, fatigué des guerres. Il respecte la force mais préfère éviter les combats inutiles.",
		"speech_style": "Parle avec lassitude, utilise des métaphores guerrières. Donne des conseilles de samouraï.",
		"mood": "fatigué mais digne",
		"persuasion_chance": 0.6,
	},
	{
		"archetype": "Bandit des montagnes",
		"personality": "Un brigand rustre et cupide. Il ne respecte que l'argent et la force brute.",
		"speech_style": "Parle de manière grossière, menace souvent, utilise l'argot des voleurs.",
		"mood": "agressif et méfiant",
		"persuasion_chance": 0.3,
	},
	{
		"archetype": "Moine guerrier",
		"personality": "Un moine bouddhiste qui a renoncé aux armes mais qui défend les faibles. Cherche la paix mais n'hésite pas à se battre pour une juste cause.",
		"speech_style": "Calme et posé, utilise des proverbes et des enseignements bouddhistes.",
		"mood": "serein mais ferme",
		"persuasion_chance": 0.7,
	},
	{
		"archetype": "Espion du clan rival",
		"personality": "Un shinobi infiltré, calculateur et silencieux. Il essaie d'obtenir des informations plutôt que de se battre.",
		"speech_style": "Parle à mots couverts, pose beaucoup de questions, ne révèle jamais ses véritables intentions.",
		"mood": "méfiant et curieux",
		"persuasion_chance": 0.5,
	},
	{
		"archetype": "Garde impérial corrompu",
		"personality": "Ancien garde du shogun, il abuse de son autorité. Vole les voyageurs mais a un point faible pour la flatterie.",
		"speech_style": "Autoritaire et arrogant, se vante de ses exploits passés, exige des tributs.",
		"mood": "arrogant et corrompu",
		"persuasion_chance": 0.4,
	},
	{
		"archetype": "Yamabushi mystique",
		"personality": "Un ascète des montagnes doté de pouvoirs mystiques. Il teste la pureté d'âme des voyageurs.",
		"speech_style": "Parle par énigmes et koans, fait référence aux esprits de la nature.",
		"mood": "mystérieux et énigmatique",
		"persuasion_chance": 0.8,
	},
	{
		"archetype": "Marchand d'armes véreux",
		"personality": "Il vend des armes aux deux camps. Il préfère négocier que se battre, toujours à la recherche d'une bonne affaire.",
		"speech_style": "Parle vite, fait des offres, essaie de marchander constamment.",
		"mood": "opportuniste et bavard",
		"persuasion_chance": 0.7,
	},
	{
		"archetype": "Paysan enrôlé de force",
		"personality": "Un simple fermier forcé de prendre les armes par son seigneur. Il n'a aucune envie de se battre et cherche une occasion de fuir.",
		"speech_style": "Timide, s'excuse souvent, parle de sa famille et de ses champs.",
		"mood": "effrayé et hésitant",
		"persuasion_chance": 0.9,
	},
	{
		"archetype": "Bushi fanatique",
		"personality": "Un guerrier dévoué à son daimyo, prêt à mourir pour l'honneur. Impossible à corrompre mais sensible aux démonstrations de force.",
		"speech_style": "Parlé de manière formelle et cérémonieuse, cite le bushido, défi constant.",
		"mood": "honorable et déterminé",
		"persuasion_chance": 0.2,
	},
	{
		"archetype": "Kunoichi solitaire",
		"personality": "Une femme ninja voyageant seule. Elle juge les gens sur leurs actes plus que leurs paroles.",
		"speech_style": "Parlé peu, va droit au but, observe plus qu'elle ne parle.",
		"mood": "distante et observatrice",
		"persuasion_chance": 0.5,
	},
]


static func get_personality(enemy_index: int, enemy_name: String = "") -> Dictionary:
	var idx := enemy_index % _PERSONALITIES.size()
	var base := _PERSONALITIES[idx].duplicate(true)
	var name_parts := enemy_name.split("#")
	var suffix := ""
	if name_parts.size() > 1:
		suffix = name_parts[1].strip_edges()
	base["name_display"] = enemy_name if not enemy_name.is_empty() else "%s #%d" % [base["archetype"], enemy_index + 1]
	base["greeting"] = _greeting_for(base["archetype"], suffix)
	base["enemy_index"] = enemy_index
	return base


static func _greeting_for(archetype: String, suffix: String) -> String:
	match archetype:
		"Ronin désabusé":
			return "Hé, voyageur. Tu cherches la guerre ou la sagesse ? J'ai assez donné."
		"Bandit des montagnes":
			return "Hé toi ! La bourse ou la vie ! ... Ou les deux, si t'es pas trop moche."
		"Moine guerrier":
			return "Que la paix soit avec toi, voyageur. Quelle affaire t'amène sur ce chemin périlleux ?"
		"Espion du clan rival":
			return "Ah... un voyageur. D'où viens-tu ? Qu'as-tu vu sur la route ?"
		"Garde impérial corrompu":
			return "Halte ! Ce chemin est sous mon autorité. Un petit... péage serait sage."
		"Yamabushi mystique":
			return "Je vois une âme troublée dans le vent. As-tu la force de regarder la vérité en face ?"
		"Marchand d'armes véreux":
			return "Ah, un client potentiel ! J'ai des katars de première qualité, presque neufs !"
		"Paysan enrôlé de force":
			return "S-s'il te plaît, ne me fais pas de mal... Je suis juste un paysan, je n'ai rien demandé..."
		"Bushi fanatique":
			return "Tu te tiens devant un serviteur du daimyo. Si tu cherches le combat, tu l'auras. Sinon, passe ton chemin."
		"Kunoichi solitaire":
			return "... Tu as du courage pour t'aventurer seul. Ou de la folie."
		_:
			return "Qui va là ? Identifie-toi, voyageur."
