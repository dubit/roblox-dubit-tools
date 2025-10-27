local function deserialisePhysicalProperties(object)
	return PhysicalProperties.new(
		object.density,
		object.friction,
		object.elasticity,
		object.frictionWeight,
		object.elasticityWeight
	)
end

local function serialisePhysicalProperties(object)
	return {
		density = object.Density,
		friction = object.Friction,
		elasticity = object.Elasticity,
		frictionWeight = object.FrictionWeight,
		elasticityWeight = object.ElasticityWeight,
	}
end

return function(Serialisation)
	Serialisation:Implement("PhysicalProperties", serialisePhysicalProperties, deserialisePhysicalProperties)
end
