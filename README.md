Needle ORM for dart.

Try to be a familar ORM framework to java programmers, so it will obey jakarta.persistence spec.

this is the generator .

annotations supported status:

[x] @Entity
[] @Column
[] @Transient
[] @Table
[] @ID
[] @Lob
[] @OneToOne
[] @OneToMany
[] @ManyToOne
[] @ManyToMany
[] @Index
[] @OrderBy
[] @Version
[] @SoftDelete

the following annotations can NOT be supported directly, but are supported in @Entity :
@PreInsert
@PreUpdate
@PreDelete
@PostInsert
@PostUpdate
@PostDelete
@PostLoad