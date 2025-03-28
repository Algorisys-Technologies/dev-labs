module.exports = (sequelize, DataTypes) => {
    const Status = sequelize.define("Status", {
      id: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        allowNull: false,
      },
      status: {
        type: DataTypes.STRING,
        allowNull: false,
      },
    },
    {
      tableName: "status", // Explicit table name
      timestamps: false,
    }
  );
  
    return Status;
  };
  